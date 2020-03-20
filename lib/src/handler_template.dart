
String handlerTemplate = """
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

var _log = Logger('{{template}}');

void generate{{Template}}(List<String> args, SendPort dartrixPort) {
  _log.info('generate{{Template}}');

  var argParser = ArgParser();
  argParser.addOption('param1', abbr: 'p',
    valueHelp: 'String',
    help: 'Param1 help',
    defaultsTo: 'Hello',
  );
  argParser.addFlag('help', abbr: 'h', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('debug', defaultsTo: false);

  ArgResults options = argParser.parse(args);

  if (options['help']) {
    print('\\npackage:{{package}}_dartrix, template: {{template}}\\n');
    print('Arguments:\\n');
    print(argParser.usage);
    exit(0);
  }

  var mydata = {
    'param1': options['param1'],
    'dartrix': {'mergeData': true}
  };
  dartrixPort.send(mydata);
}
""";
