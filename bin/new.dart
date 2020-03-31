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
import 'package:dartrix/src/dispatcher.dart';
// import 'package:dartrix/src/paths.dart';
import 'package:dartrix/src/plugins.dart';
import 'package:dartrix/src/utils.dart';

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

Map getTemplateArgs(List<String> subArgs) {
  // print('getTemplate: $subArgs');
  List<String> libArgs = [];
  List<String> tArgs = [];

  var ft;
  var template;
  ft = subArgs.indexOf('--template');
  if (ft < 0) {
    // --template not found
    ft = subArgs.indexOf('-t');
    if (ft < 0) {
      // -t not found
      Config.prodLogger.w('Missing required template option: -t | --template');
      if ((subArgs.contains('-h') || subArgs.contains('--help'))) {
        libArgs = subArgs.sublist(1);
        tArgs.add('-h');
      } else {
        exit(0);
      }
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
      libArgs = subArgs.sublist(0, ft);
      // print('libArgs: $libArgs');
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
    libArgs = subArgs.sublist(0, ft);
    tArgs = subArgs.sublist(ft + 2);
  }
  // print('template: $template');
  // print('libArgs: $libArgs');
  // print('tArgs: $tArgs');
  return {'template': template, 'libArgs': libArgs, 'tArgs': tArgs};
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

  var templateArgs = getTemplateArgs(optionsRest); //, libArgs, tArgs);
  // Config.ppLogger.i('templateArgs: ${templateArgs["template"]}');
  // Config.logger.i('libArgs: ${templateArgs["libArgs"]}');
  // Config.logger.i('tArgs: ${templateArgs["tArgs"]}');

  // FIXME: initializing data to be done by each template
  if (optionsRest.isNotEmpty && (Config.options.command == null)) {
    Config.libName = optionsRest[0];

    Config.libName = normalizeLibName(Config.libName);

    var pkgList = await resolvePkg(Config.libName);
    // print('pkgList: $pkgList');
    if (pkgList == null) {
      print('Template library ${Config.libName} not found.');
      exit(0);
    }

    if (pkgList.isEmpty) {
      print('No templates found in template library ${Config.libName}');
      exit(0);
    }

    // Config.ppLogger.i('pkgList: $pkgList');

    // resolvePkg returns list, first item is preferred
    Config.libPkgRoot = pkgList[0]['rootUri'];

    // Config.ppLogger.v('libPkgRoot: ${Config.libPkgRoot}');

    switch (Config.libName) {
      // no need to verify app version for builtins, home, here, local
      case ':d':
      case ':dartrix': // Config.appName:
      break;
      case ':.':
      case ':here':
      case ':h':
      case ':home':
      break;
      case ':l':
      case ':local':
      break;
      default: // nop
        var requiredVersion = await verifyAppVersion(Config.libPkgRoot);
        if (requiredVersion != null) {
          Config.prodLogger.e(
              'Plugin \'${Config.libName}\' requires Dartrix version $requiredVersion; current version is ${await Config.appVersion}.');
          exit(0);
        }
    }
    // print('libpkgroot: ${Config.libPkgRoot}');
    if (!(optionsRest.contains('-h') || optionsRest.contains('--help'))) {
      var t = Config.libPkgRoot +
          '/' +
          ((Config.libPkgRoot == '.') ? '.' : '') +
          'templates/' +
          templateArgs['template'];
      // print('t: $t');
      if (!verifyExists(t)) {
        Config.prodLogger.e(
            'Template ${templateArgs["template"]} not found in library ${Config.libName}');
        exit(0);
      }
    }

    if (Config.debug) {
      print('Config.options:');
      debug.debugConfig();
    }

    switch (Config.libName) {
      case ':.':
      case ':here':
        dispatchHere(templateArgs['template'], Config.options,
            templateArgs['libArgs'], templateArgs['tArgs']); // optionsRest);
        break;
      case ':d':
      case ':dartrix':
        dispatchBuiltin(templateArgs['template'], Config.options,
            templateArgs['libArgs'], templateArgs['tArgs']); // optionsRest);
        break;
      case ':h':
      case ':home':
        dispatchUser(templateArgs['template'], Config.options,
            templateArgs['libArgs'], templateArgs['tArgs']);
        break;
      case ':l':
      case ':local':
        dispatchLocal(templateArgs['template'], Config.options,
            templateArgs['libArgs'], templateArgs['tArgs']); // optionsRest);
        break;
        break;
      default:
        await dispatchPlugin(
            Config.libName,
            templateArgs['template'],
            Config.options,
            templateArgs['libArgs'],
            templateArgs['tArgs']); // optionsRest);
    }
  }
}
