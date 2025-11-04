import 'package:mono_cli/mono_cli.dart';

void main() {
  final tokenizer = ArgsTokenizer();
  final tokens = tokenizer.tokenize('list all --check -t app');
  final parser = ArgsCliParser();
  final invocation = parser.parse(['list', '--check', 'all', '-t', 'app']);

  const yamlText = '''
include:
  - packages/*
tasks:
  build:
    run: [dart, compile]
''';
  const loader = YamlConfigLoader();
  final config = loader.load(yamlText);

  const logger = StdLogger();
  logger.log('Tokens: $tokens', scope: 'example');
  logger.log('Command: ${invocation.commandPath.join(' ')}', scope: 'example');
  logger.log('Config include: ${config.include}', scope: 'example');
}
