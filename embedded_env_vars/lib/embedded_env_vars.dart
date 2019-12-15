/// Marks a class as a container for embedded environment variables.
const embeddedEnvironmentVariables = EmbeddedEnvironmentVariables();

/// See [embeddedEnvironmentVariables].
class EmbeddedEnvironmentVariables {
  const EmbeddedEnvironmentVariables();
}

/// Marks a getter as a host for an embedded environment variables.
/// 
/// The generated implementing class will contain an override for
/// getters annotated with this.
/// 
/// The getter must return a [String].
class EnvironmentVariable {
  /// The environment variable name.
  final String variableName;

  /// The default value to use if the environment variable
  /// does not exist.
  /// 
  /// Defaults to `null`.
  final String defaultValue;

  const EnvironmentVariable(this.variableName, {this.defaultValue})
    : assert(variableName != null);
}
