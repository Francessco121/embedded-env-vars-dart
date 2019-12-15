import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:embedded_env_vars/embedded_env_vars.dart';
import 'package:source_gen/source_gen.dart' as source_gen;

import 'build_exception.dart';

const _classAnnotationTypeChecker = source_gen.TypeChecker.fromRuntime(EmbeddedEnvironmentVariables);
const _getterAnnotationTypeChecker = source_gen.TypeChecker.fromRuntime(EnvironmentVariable);

class EnvGenerator extends source_gen.Generator {
  EnvGenerator();

  @override
  FutureOr<String> generate(source_gen.LibraryReader library, BuildStep buildStep) async {
    // Build classes
    final List<Class> classes = [];
    final Set<String> generatedClasses = new Set<String>();

    for (final annotatedElement in library.annotatedWith(_classAnnotationTypeChecker)) {
      if (annotatedElement.element is! ClassElement) {
        throw BuildException(
          'Only classes may be annotated with @EmbeddedEnvironmentVariables!',
          annotatedElement.element
        );
      }

      for (Class $class in _generateClasses(annotatedElement.element, generatedClasses)) {
        classes.add($class);
      }
    }

    // Check if any classes were generated
    if (classes.isEmpty) {
      // Don't create a file if nothing was generated
      return null;
    }

    // Build library
    final libraryAst = Library((l) => l
      ..body.addAll(classes)
    );

    // Emit source
    final emitter = new DartEmitter(Allocator.simplePrefixing());
    
    return libraryAst.accept(emitter).toString();
  }

  /// Generates a class for the given [$class] element.
  Iterable<Class> _generateClasses(
    ClassElement $class, 
    Set<String> generatedClasses
  ) sync* {
    if (generatedClasses.contains($class.name)) {
      // This class has already been generated
      return;
    }

    generatedClasses.add($class.name);

    final List<Field> fields = [];

    Iterable<PropertyAccessorElement> getters = $class.accessors
      .where((accessor) => accessor.isGetter);

    for (PropertyAccessorElement getter in getters) {
      // Get the @EnvironmentVariable annotation
      final DartObject annotation = _getterAnnotationTypeChecker.firstAnnotationOf(getter);

      if (annotation == null) {
        throw BuildException('Missing @EnvironmentVariable annotation.', getter);
      }

      // Read the environment variable name and default
      final annotationReader = source_gen.ConstantReader(annotation);

      final source_gen.ConstantReader environmentVariableNameReader = annotationReader
        .read('variableName');

      final String environmentVariableName = environmentVariableNameReader.isNull
        ? null
        : environmentVariableNameReader.stringValue;

      final source_gen.ConstantReader environmentVariableDefaultReader = annotationReader
        .read('defaultValue');

      final String environmentVariableDefault = environmentVariableDefaultReader.isNull
        ? null
        : environmentVariableDefaultReader.stringValue;

      if (environmentVariableName == null) {
        throw BuildException('Environment variable name cannot be null.', getter);
      }

      // Get the actual environment variable value
      final String environmentVariable = Platform.environment[environmentVariableName] ?? environmentVariableDefault;

      // Generate a field for the variable
      fields.add(Field((f) => f
        ..annotations.add(refer('override'))
        ..modifier = FieldModifier.final$
        ..type = refer('String')
        ..name = getter.name
        ..assignment = _codeString(environmentVariable)
      ));
    }

    // Build class
    yield Class((c) => c
      ..name = _generatedClassNameOf($class.name)
      ..implements.add(refer($class.name))
      ..fields.addAll(fields)
      ..constructors.add(Constructor((t) => t
        ..constant = true
      ))
    );
  }

  Code _codeString(String value) {
    if (value == null) return const Code('null');

    return Code(_makeStringLiteral(value));
  }

  String _generatedClassNameOf(String className) {
    return '_\$${className}Embedded';
  }

  String _makeStringLiteral(String value) {
    value = value
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'");

    return "'$value'";
  }
}
