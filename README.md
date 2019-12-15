# embedded_env_vars

An experimental package for embedding environment variables at build time into application code.

## Usage

### Depend on the package
```yaml
# Add a normal dependency on the annotations package
dependencies:
  embedded_env_vars:
    git: 
      url: https://github.com/Francessco121/embedded-env-vars-dart.git
      path: embedded_env_vars
      ref: <insert latest commit ID> # Optional but recommended

# Add a dev dependency on the generator package
dev_dependencies:
  embedded_env_vars_generator:
    git: 
      url: https://github.com/Francessco121/embedded-env-vars-dart.git
      path: embedded_env_vars_generator
      ref: <insert latest commit ID> # Optional but recommended
```

### Example
```dart
// file: environment.dart

// Import the annotations package
import 'package:embedded_env_vars/embedded_env_vars.dart';

// Include the generated part file with the real environment 
// variable values
part 'environment.env.dart';

// Mark an abstract class as a container for embedded 
// environment variables
@embeddedEnvironmentVariables
abstract class Environment {
  // Specify environment variables as a String getter with an 
  // optional default value
  @EnvironmentVariable('BUILD_ID', defaultValue: '0')
  String get buildId;

  // Let importing code get an implementation of this class 
  // containing the real environment variable values
  //
  // _$EnvironmentEmbedded implements Environment
  factory Environment() => const _$EnvironmentEmbedded();
}
```
