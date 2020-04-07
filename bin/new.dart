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
  print('dartrix:new,  version ${await Config.appVersion}');
  print('Generate new resources from a template.\n');
  print(
      'Usage:\tdartrix:new [options] LIBRARY [lib-options] -t TEMPLATE [template-options]\n');
  ;
  print('Options:');
  print(argParser.usage);
}

Map getTemplateArgs(List<String> subArgs) {
  // Config.ppLogger.i('''1d89f670-38af-4707-82f4-f8a501acac1a: getTemplateArgs: $subArgs''');
  List<String> libArgs = [];
  List<String> tArgs = [];
  String template;

  var ft;
  var tlib = subArgs[0];
  if (tlib.startsWith(':')) {
    libArgs.add(tlib);
    subArgs = subArgs.sublist(1);
    template = subArgs[0];
    if (template == '--help') {
      // print help for tlib, if any
      exit(0);
    }
    if ( !RegExp(r'^[a-z]').hasMatch(template) ) {
      print('''09b7d2e2-37ea-46c2-b98a-bbd4e2d77a21:  REGEXP fail''');
      exit(1);
    }
    subArgs = subArgs.sublist(1);
    tArgs = subArgs;
  } else {
    Config.prodLogger.e('Invalid library tag: $tlib. Library tags start with \':\'; did you mean  \':$tlib\'?');
  }

  // ft = subArgs.indexOf('--template');
  // if (ft < 0) {
  //   // --template not found
  //   ft = subArgs.indexOf('-t');
  //   if (ft < 0) {
  //     // -t not found
  //     if ((subArgs.contains('-h') || subArgs.contains('--help'))) {
  //       libArgs = subArgs.sublist(1);
  //       tArgs.add('-h');
  //     } else {
  //       Config.prodLogger.w('Missing required template option: -t | --template');
  //       exit(0);
  //     }
  //   } else {
  //     if (ft != subArgs.lastIndexOf('-t')) {
  //       Config.prodLogger.e('Multiple --template options not allowed.');
  //       exit(0);
  //     }
  //     if (subArgs.contains('--template')) {
  //       Config.prodLogger.e('Only one -t or --template option allowed.');
  //       exit(0);
  //     }
  //     template = subArgs[ft + 1];
  //     libArgs = subArgs.sublist(0, ft);
  //     // print('libArgs: $libArgs');
  //     tArgs = subArgs.sublist(ft + 2);
  //     // print('tArgs: $tArgs');
  //   }
  // } else {
  //   // Config.logger.e('found --template');
  //   if (ft != subArgs.lastIndexOf('--template')) {
  //     Config.prodLogger.e('Only one -t or --template option allowed.');
  //     exit(0);
  //   }
  //   if (subArgs.contains('-t')) {
  //     Config.prodLogger.e('Only one -t or --template option allowed.');
  //     exit(0);
  //   }
  //   template = subArgs[ft + 1];
  //   libArgs = subArgs.sublist(0, ft);
  //   tArgs = subArgs.sublist(ft + 2);
  // }
  // print('template: $template');
  // print('libArgs: $libArgs');
  // print('tArgs: $tArgs');
  return {'lib': tlib, 'libArgs': libArgs, 'template': template, 'tArgs': tArgs};
}

void main(List<String> args) async {
  if (args.contains('--debug')) Config.debug = true;
  await Config.config('dartrix');

  Config.argParser = ArgParser(allowTrailingOptions: false);
  // Config.argParser.addOption('config-file',
  //     help: 'Configuration file. Optional.', defaultsTo: './dartrix.yaml');
  Config.argParser.addFlag('dry-run', help: 'Print list of outputs but do not actual write any output.', defaultsTo: false, negatable: false);
  Config.argParser.addFlag('force', help: 'Force over-write of existing files.', defaultsTo: false, negatable: false);
  Config.argParser.addFlag('here', help: 'Write output to :here (./.dartrix/templates); for use with meta-templates and --Y only.', defaultsTo: false, negatable: false);
  Config.argParser.addFlag('Y', help: 'Pseudo Y-combinator; causes template to copy itself.', defaultsTo: false, negatable: false);
  Config.argParser
      .addFlag('help', defaultsTo: false, negatable: false);
  Config.argParser
      .addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
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

  // System options: propagate to Config, then remove from args list.
  // Exception: --here and -Y
  if (Config.options['debug'] || optionsRest.contains('--debug')) {
    debug.debug = true;
    Config.debug = true;
    optionsRest.remove('--debug');
  }

  if (debug.debug) {
    debug.debugOptions();
    debug.debugConfig();
  }

  if (Config.options['dry-run'] || optionsRest.contains('--dry-run')) {
    Config.verbose = true;
    Config.dryRun = true;
    Config.ppLogger.w('Dry-run...');
    optionsRest.remove('--dry-run');
  }

  if (Config.options['force'] ||
      // optionsRest.contains('-f') ||
      optionsRest.contains('--force')) {
    // tData['dartrix']['force'] = true;
    Config.force = true;
    // optionsRest.remove('-f');
    optionsRest.remove('--force');
  }

  if (Config.options['verbose'] ||
      optionsRest.contains('-v') ||
      optionsRest.contains('--verbose')) {
    Config.verbose = true;
    optionsRest.remove('-v');
    optionsRest.remove('--verbose');
  }

  if (Config.options['here']) {
    Config.here = true;
    optionsRest.remove('--here');
  }

  if (Config.options['Y']) {
    Config.Y = true;
    optionsRest.remove('--Y');
  }

  if (Config.options['help']) {
    await printUsage(Config.argParser);
    if (optionsRest.isEmpty) {
      exit(0);
    } else {
      optionsRest.add('--help');
    }
  } else {
    if (optionsRest.contains('--help')) {
      await printUsage(Config.argParser);
    }
  }

  // if (Config.options['config-file'] != null)
  // await loadConfigFile(Config.options['config-file']);

  // var cmd = Config.options.command;
  // Config.logger.d('cmd: $cmd');

  var templateArgs = getTemplateArgs(optionsRest); //, libArgs, tArgs);
  // print('''7aece02c-e16f-4a2e-b168-23c0a285fd6c: args $templateArgs''');
  // print('''a5a41171-478c-4a27-8fa7-f2394b7c08aa: libArgs: ${templateArgs["libArgs"]}''');
  // print('''d3078ca3-db82-4c47-b209-a18c2698413b: tArgs: ${templateArgs["tArgs"]}''');

  // FIXME: initializing data to be done by each template
  if (optionsRest.isNotEmpty && (Config.options.command == null)) {
    Config.libName = optionsRest[0];

    Config.libName = canonicalizeLibName(Config.libName);

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
    // print('rootUri: ${pkgList[0]["rootUri"]}');
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
      break;
      case ':user':
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
    // print('libName: ${Config.libName}');
    if (!(optionsRest.contains('-h') || optionsRest.contains('--help'))) {
      var t = Config.libPkgRoot
          + '/templates/'
          + templateArgs['template'];
      // print('t: $t');
      if (!verifyExists(t)) {
        Config.prodLogger.e(
            'Template \'${Config.libName} ${templateArgs["template"]}\' not found (${t}).');
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
        await dispatchBuiltin(templateArgs['template'], Config.options,
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
  if (Config.dryRun) {
    Config.ppLogger.w('This was a dry-run. No output was generated.');
  }
}
