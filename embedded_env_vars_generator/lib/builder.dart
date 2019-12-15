import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/env_generator.dart';

Builder envBuilder(BuilderOptions options) {
  return PartBuilder([EnvGenerator()], '.env.dart');
}