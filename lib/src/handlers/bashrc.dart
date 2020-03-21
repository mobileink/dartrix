import 'dart:io';

import 'package:args/args.dart';
import 'package:logger/logger.dart';
// import 'package:path/path.dart' as path;
import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';

import 'package:dartrix/src/builtins.dart';

void handleBashrc(List<String> subArgs) async {
  // Config.logger.i('handleBashrc, subargs $subArgs');
  if (Config.options['help']) {
    print('template "bashrc" parameters:');
    print('\t-p, --pfx  cmd prefix');
    exit(0);
  }
  //ArgParser
  var argParser = ArgParser(allowTrailingOptions: false);
  argParser.addOption('prefix',
      abbr: 'p',
      defaultsTo: 't',
      valueHelp: '[a-z][a-z0-9_]*',
      help: 'Prefix for command aliases.');
  ArgResults options;
  try {
    options = argParser.parse(subArgs);
  } catch (e) {
    Config.logger.e('template ${Config.options["template"]}: $e');
    exit(0);
  }
  // Config.logger.i('bashrc options: ${options.options}');

  if (Config.options['out'] == Config.argParser.getDefault('out')) {
    // user did not override, use plugin's default
    tData['out'] = Config.home;
    // Config.logger.i('OUTx: ${tData['out']}');
  }
  // Config.logger.i('OUT: ${tData['out']}');
  tData['pfx'] = options['prefix'];
  generateFromBuiltin();
}
