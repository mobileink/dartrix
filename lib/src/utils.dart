import 'dart:io';

import 'package:args/args.dart';
// import 'package:ansicolor/ansicolor.dart';
// import 'package:logger/logger.dart';
// import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
// import 'package:dartrix/src/debug.dart' as debug;
// import 'package:dartrix/src/utils.dart';

//var Config.logger = Logger('utils');

/// Verify that cwd is root of a Dartrix package.
void sanityCheck() {
  if (Config.verbose) Config.logger.i('Sanity check...');
  var cwd = Directory.current.path;
  var cwdName = path.basename(Directory.current.path);
  if (!cwdName.endsWith(Config.appSfx)) {
    Config.logger.w(
        'Not in a dartrix package directory. Package name (cwd) must end in "_dartrix".');
    exit(0);
  }
  if (Config.verbose) Config.logger.i('... cwd ends with "_dartrix" - ok');

  var mainDart = 'lib/' + cwdName + '.dart';
  var exists = FileSystemEntity.typeSync(mainDart);
  if (exists == FileSystemEntityType.notFound) {
    Config.logger.e('${mainDart} not found');
    exit(0);
  }
  if (Config.verbose) Config.logger.i('... .${mainDart} exists - ok');

  exists = FileSystemEntity.typeSync(cwd + '/templates');
  if (exists == FileSystemEntityType.notFound) {
    Config.logger.e('./templates directory not found');
    exit(0);
  }
  if (Config.verbose) Config.logger.i('... ./templates directory exists - ok');

  exists = FileSystemEntity.typeSync(cwd + '/man');
  if (exists == FileSystemEntityType.notFound) {
    Config.logger.e('./man directory not found');
    exit(0);
  }
  if (Config.verbose) Config.logger.i('... ./man directory exists - ok');

  if (Config.verbose) Config.logger.i('Sanity check passed.');
}

void processArgs(String dir, List<String> tArgs) async {
  // Config.debugLogger.v('processArgs: $dir, $tArgs');

  // 1. construct arg parser from yaml file
  // next: construct arg parser from yaml file

  var template = path.basename(dir);
  // Config.logger.v('processArgs template: $template');

  var yaml = getTemplateConfig(dir); // templates['dart_cmdsuite']['root']);
  // + '/templates/' + template);
  // Config.logger.i('yaml: ${yaml.params}');

  var _argParser = ArgParser(allowTrailingOptions: true, usageLineLength: 100);
  yaml.params.forEach((param) {
    // Config.logger.i('param: $param');
    if (param.typeHelp == 'bool') {
      _argParser.addFlag(param.name,
          abbr: param.abbr,
          help: param.help,
          defaultsTo: (param.defaultsTo == 'true') ? true : false);
    } else {
      _argParser.addOption(param.name,
          abbr: param.abbr,
          valueHelp: param.typeHelp,
          help: param.docstring,
          //+ param?.help ,
          defaultsTo: param.defaultsTo);
    }
  });
  // always add --help
  _argParser.addFlag('help', abbr: 'h', defaultsTo: false, negatable: false);

  if (Config.debug) {
    Config.debugLogger
        .i('Params for template $template: ${_argParser.options}');
  }

  // print(_argParser.usage);
  // exit(0);

  // first arg is 'dartrix', omit
  // var myargs = _options.rest.sublist(1);
  // print('tArgs: $tArgs');
  var myoptions;
  try {
    myoptions = _argParser.parse(tArgs);
  } catch (e) {
    Config.debugLogger.e(e);
    exit(0);
  }
  // print('myoptions: ${myoptions.options}');
  // print('args: ${myoptions.arguments}');

  if (myoptions.wasParsed('help')) {
    // printUsage(_argParser);
    print('\nTemplate \'$template\' options:');
    print(_argParser.usage);
    exit(0);
  }

  // now merge user passed args with default data map
  // print('MERGE user options');
  myoptions.options.forEach((option) {
    // print('option: ${option} = ${myoptions[option]}');
    // print('params rtt: ${yaml.params.runtimeType}');
    var param;
    try {
      param = yaml.params.firstWhere((param) {
        return param.name == option;
      });
      // print('yaml: ${param.name}');
      if (param.segmap != null) {
        tData['segmap'][param.segmap] = myoptions[option];
        tData[option] = myoptions[option];
      } else {
        tData[option] = myoptions[option];
      }
      // if (params['segment'] == null) {
      // } else {
      // }
    } catch (e) {
      // this will happen for e.g. the help option that was not specified in
      // the yaml file.
      // print(e);
    }
  });
}
