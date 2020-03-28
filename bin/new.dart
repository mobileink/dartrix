import 'dart:io';

import 'package:args/args.dart';
// import 'package:args/command_runner.dart';
// import 'package:path/path.dart' as path;
// import 'package:process_run/which.dart';
// import 'package:strings/strings.dart';

import 'package:dartrix/dartrix.dart';
import 'package:dartrix/src/builtins.dart';
import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
// import 'package:dartrix/src/paths.dart';
import 'package:dartrix/src/plugins.dart';
// import 'package:dartrix/src/utils.dart';

String http_parser_pkg = 'package:http_parser';
String hello_pkg = 'package:hello_template';

void validateSnakeCase(String pkg) {
  final r = RegExp(r'^[a-z_][a-z0-9_]*$');
  if (!r.hasMatch(pkg)) {
    Config.logger.w('Invalid name (snake_case): $pkg');
    exit(0);
  }
}

void validateCamelCase(String name) {
  final r = RegExp(r'^[A-Z][A-Za-z0-9_]*$');
  if (!r.hasMatch(name)) {
    Config.logger.w('Invalid name (CamelCase): $name');
    exit(0);
  }
}

void validateTemplateName(String t) {
  validateSnakeCase(t);
}

// String getInDir(String template) {

//   // If template is built-in, proceed, else call resolution fn

//   String p = path.prettyUri(Platform.script.toString());
//   // Config.logger.d('inDir 1: $p');
//   String inDir = path.dirname(p) + '/..';
//   var inPfx = path.canonicalize(inDir);
//   // Config.logger.d('inPfx 2: $inPfx');
//   if (template == 'split-plugin') {
//     inDir = inPfx + '/mustache/plugins/greetings-services';
//   } else {
//     inDir = inPfx + '/mustache/plugins/greetings';
//   }
// }

void printUsage(ArgParser argParser) async {
  // print('\n\t\tDartrix Templating System - "new" command\n');
  print('dartrix:new,  version ${await Config.appVersion}\n');
  print(
      'usage:\tdartrix:new [options] LIBRARY [lib-options] -t TEMPLATE [template-options]\n');
  ;
  print('Options:');
  print(argParser.usage);
}

Map getTemplate(List<String> subArgs) {
  // print('getTemplate: $subArgs');
  List<String> dartrixArgs;
  List<String> tArgs;

  var ft;
  var template;
  ft = subArgs.indexOf('--template');
  if (ft < 0) {
    // not found
    ft = subArgs.indexOf('-t');
    if (ft < 0) {
      // not found
      Config.prodLogger.e('Missing required template option: -t | --template');
      exit(0);
    } else {
      if (ft != subArgs.lastIndexOf('-t')) {
        Config.prodLogger.e('Multiple --template options not allowed.');
        exit(0);
      }
      if (subArgs.contains('--template')) {
        Config.prodLogger.e('Only one -t or --template option allowed.');
        exit(0);
      }
      template = subArgs[ft + 1];
      dartrixArgs = subArgs.sublist(0, ft);
      // print('dartrixArgs: $dartrixArgs');
      tArgs = subArgs.sublist(ft + 2);
      // print('tArgs: $tArgs');
    }
  } else {
    // Config.logger.e('found --template');
    if (ft != subArgs.lastIndexOf('--template')) {
      Config.prodLogger.e('Only one -t or --template option allowed.');
      exit(0);
    }
    if (subArgs.contains('-t')) {
      Config.prodLogger.e('Only one -t or --template option allowed.');
      exit(0);
    }
    template = subArgs[ft + 1];
    dartrixArgs = subArgs.sublist(0, ft);
    tArgs = subArgs.sublist(ft + 2);
  }
  // print('template: $template');
  // print('dartrixArgs: $dartrixArgs');
  // print('tArgs: $tArgs');
  return {'template': template, 'dartrixArgs': dartrixArgs, 'tArgs': tArgs};
}

void main(List<String> args) async {
  if (args.contains('--debug')) Config.debug = true;
  await Config.config('dartrix');

  Config.argParser = ArgParser(allowTrailingOptions: false);
  Config.argParser
      .addFlag('help', abbr: 'h', defaultsTo: false, negatable: false);
  Config.argParser
      .addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
  Config.argParser.addOption('config-file',
      help: 'Configuration file.', defaultsTo: './dartrix.yaml');
  Config.argParser.addFlag('dry-run', defaultsTo: false, negatable: false);
  Config.argParser.addFlag('force', defaultsTo: false, negatable: false);
  Config.argParser.addFlag('version', defaultsTo: false, negatable: false);
  Config.argParser.addFlag('debug', defaultsTo: false, negatable: false);

  try {
    Config.options = Config.argParser.parse(args);
  } catch (e) {
    Config.prodLogger.e(e);
    exit(0);
  }

  var optionsRest = Config.options.rest.toList();

  if (args.isEmpty) {
    await printUsage(Config.argParser);
    exit(0);
  }

  // if (Config.options['debug']) {
  //   debug.debug = true;
  //   Config.debug = true;
  // }

  if (Config.options['debug'] || optionsRest.contains('--debug')) {
    debug.debug = true;
    Config.debug = true;
    optionsRest.remove('--debug');
  }

  if (Config.options['verbose'] ||
      optionsRest.contains('-v') ||
      optionsRest.contains('--verbose')) {
    Config.verbose = true;
    optionsRest.remove('-v');
    optionsRest.remove('--verbose');
  }

  if (Config.options['dry-run'] || optionsRest.contains('--dry-run')) {
    Config.verbose = true;
    Config.dryRun = true;
    Config.ppLogger.w('Dry-run...');
    optionsRest.remove('--dry-run');
  }

  if (Config.options['force'] ||
      optionsRest.contains('-f') ||
      optionsRest.contains('--force')) {
    tData['dartrix']['force'] = true;
    optionsRest.remove('-f');
    optionsRest.remove('--force');
  }

  if (debug.debug) debug.debugOptions();

  if (Config.options['help']) {
    await printUsage(Config.argParser);
    optionsRest.add('-h');
  } else {
    if (optionsRest.contains('-h') || optionsRest.contains('--help')) {
      await printUsage(Config.argParser);
    }
  }

  // if (Config.options['config-file'] != null)
  // await loadConfigFile(Config.options['config-file']);

  // var cmd = Config.options.command;
  // Config.logger.d('cmd: $cmd');

  var template = getTemplate(optionsRest); //, dartrixArgs, tArgs);
  // Config.ppLogger.i('template: ${template["template"]}');
  // Config.logger.i('dartrixArgs: ${template["dartrixArgs"]}');
  // Config.logger.i('tArgs: ${template["tArgs"]}');

  // FIXME: initializing data to be done by each template
  if (optionsRest.isNotEmpty && (Config.options.command == null)) {
    var libName = optionsRest[0];

    Config.libName = libName;

    var pkg = await resolvePkg(libName);
    Config.libPkgRoot = pkg['rootUri'];

    // Config.ppLogger.v('libname: $libName');

    if (libName != Config.appName) {
      var requiredVersion = await verifyAppVersion(Config.libPkgRoot);
      if (requiredVersion != null) {
        Config.prodLogger.e(
            'Plugin \'$libName\' requires Dartrix version $requiredVersion; current version is ${await Config.appVersion}.');
        exit(0);
      }
    }
    if (!verifyExists(
        Config.libPkgRoot + '/templates/' + template['template'])) {
      Config.prodLogger
          .e('Template ${template["template"]} not found in library $libName');
      exit(0);
    }

    if (Config.debug) {
      debug.debugConfig();
    }

    switch (libName) {
      case 'dartrix':
        dispatchBuiltin(template['template'], Config.options,
            template['dartrixArgs'], template['tArgs']); // optionsRest);
        break;
      default:
        await dispatchPlugin(libName, template['template'], Config.options,
            template['dartrixArgs'], template['tArgs']); // optionsRest);
    }
  }
}
