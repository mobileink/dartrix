import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
// import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;

import 'package:dartrix/src/builtins.dart';

var _log = Logger('dart_clix');

void handleDartClix(List<String> subArgs) async {
  _log.info('handleDartClix, subargs $subArgs');

  if (debug.debug) {
    debug.debugOptions();
    debug.debugData({});
  }

  var argParser = ArgParser(allowTrailingOptions: false);
  argParser.addOption('homepage',
    // abbr: 'h',
    defaultsTo: 'https://example.org/myapp',
    valueHelp: 'URL',
    help: 'Homepage for app.');

  argParser.addFlag('help', abbr: 'h', defaultsTo: false);

  ArgResults options;
  try {
    options = argParser.parse(subArgs);
  } catch (e) {
    _log.severe('template ${Config.options["template"]}: $e');
    exit(0);
  }
  _log.info('dart_clix options: ${options.options}');

  if (options['help']) {
    print('template "dart_clix" parameters:');
    print(argParser.usage);
    exit(0);
  }

  if (options['homepage'] == argParser.getDefault('homepage')) {
    _log.warning('Using default homepage ${options["homepage"]} for pubspec.yaml.');
  }
  tData['homepage'] = options['homepage'];

  if (Config.options['package'] == Config.argParser.getDefault('package')) {
    // user did not override, set plugin default:
    tData['package']['dart'] = 'myapp';
  }
  tData['homepage'] = options['homepage'];

  if (Config.options['out'] == Config.argParser.getDefault('out')) {
    // user did not override, use plugin's default
    // tData['out'] = Config.home;
    _log.info('OUTx: ${tData['out']}');
  }
  _log.info('OUT: ${tData['out']}');
  generateFromBuiltin();
}
