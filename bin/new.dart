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
  print('dartrix:new,  version ${await Config.pkgVersion}\n');
  print('usage:\tdartrix:new [options] LIBRARY -t TEMPLATE [template-options]');
  // print('Usage:');
  // print('  Builtins: pub global run dartrix:new [ordpcfhvt]\n');
  // print(
  //     '  Plugins: pub global run dartrix:new [ordpcfv] plugin [th][toptions]\n');
  // print(
  //     '\t plugin:  pkg:package_name | package:package_name | path:path/to/package_name\n');
  // print('\t toptions:  per template; pass -h or use dartrix:man to view.\n');
  print('Options:');
  print(argParser.usage);
  await printAvailableLibs();

  // await printBuiltins();
  // print(
  //     '\nTo list available commands and templates: pub global run dartrix:list\n');
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
  // Config.argParser.addOption(
  //   'template', abbr: 't', // defaultsTo: 'hello',
  //   valueHelp: '[a-z][a-z0-9_]*',
  //   help: 'Template name.',
  //   // callback: (t) => validateTemplateName(t)
  // );
  // Config.argParser.addOption('relative-root', abbr: 'r',
  //   defaultsTo: Directory.current.path,
  //     valueHelp: 'directory',
  //     help:
  //     'Root of template output, relative to ROOT prefix path. Defaults to cwd.',
  //     // Defaults to value of --package arg (i.e. "hello").'
  //     // callback: (pkg) => validateSnakeCase(pkg)
  //     );
  // Config.argParser.addOption('ROOT',
  //     abbr: 'R',
  //     defaultsTo: Config.home,
  //     help: 'Absolute output path.',
  //     valueHelp: '/path/to/template/output.');
  // Config.argParser.addOption('domain',
  //     abbr: 'd',
  //     defaultsTo: 'example.org',
  //     help:
  //         'Domain name. Must be legal as a Java package name;\ne.g. must not begin with a number, or match a Java keyword.',
  //     valueHelp: 'segmented.domain.name');
  // Config.argParser.addOption('package',
  //     abbr: 'p',
  //     defaultsTo: 'hello',
  //     valueHelp: '[_a-z][a-z0-9_]*',
  //     help: 'snake_cased name.  Used e.g. as Dart package name.',
  //     callback: (pkg) => validateSnakeCase(pkg));
  // Config.argParser.addOption('class',
  //     abbr: 'c',
  //     defaultsTo: 'Hello',
  //     valueHelp: '[A-Z][a-zA-Z0-9_]*',
  //     help:
  //         'CamelCased name. Used as class/type name for Java, Kotline, etc.\nDefaults to --package value, CamelCased (i.e. "Hello").\nE.g. -p foo_bar => -c FooBar.',
  //     callback: (name) => validateCamelCase(name));
  // Config.argParser.addOption('plugin', abbr: 'x',
  //   valueHelp: 'path:path/to/local/pkg | package:pkg_name',
  //   help: 'External template package'
  //   // defaultsTo: 'plugin',
  //   // callback: (t) => validateTemplateName(t)
  // );
  // Config.argParser.addFlag('list', abbr: 'l',
  //   help: 'List plugins.',
  //   defaultsTo: false,
  // );
  Config.argParser.addFlag('dry-run', defaultsTo: false);
  Config.argParser.addFlag('force', abbr: 'f', defaultsTo: false);
  Config.argParser
      .addFlag('help', abbr: 'h', defaultsTo: false, negatable: false);
  Config.argParser
      .addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false);
  Config.argParser.addFlag('version', defaultsTo: false, negatable: false);
  Config.argParser.addFlag('debug', defaultsTo: false, negatable: false);

  // Config.argParser.addFlag('manpage', defaultsTo: false);

  // var pluginCmd = ArgParser.allowAnything();
  // Config.argParser.addCommand('pkg:', pluginCmd);
  // // var packageCmd = ArgParser.allowAnything();
  // Config.argParser.addCommand('package:', pluginCmd);
  // // var pathCmd = ArgParser.allowAnything();
  // Config.argParser.addCommand('path:', pluginCmd);

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
    // if (args.contains('-t') || args.contains('template')) {
    //   if (args.contains('-h') &&
    //       ((args.indexOf('-h') < args.indexOf('-t')) ||
    //           (args.indexOf('-h') < args.indexOf('--template')))) {
    //     await printUsage(Config.argParser);
    //     // exit(0);
    //   } else {
    //     if (args.contains('--help') &&
    //         ((args.indexOf('--help') < args.indexOf('-t')) ||
    //             (args.indexOf('--help') < args.indexOf('--template')))) {
    //       await printUsage(Config.argParser);
    //       // exit(0);
    //     }
    //   }
    // } else {
    //   await printUsage(Config.argParser);
    // }
  }
  // var cmd = Config.options.command;
  // Config.logger.d('cmd: $cmd');

  var template = getTemplate(optionsRest); //, dartrixArgs, tArgs);
  // Config.ppLogger.i('template: ${template["template"]}');
  // Config.logger.i('dartrixArgs: ${template["dartrixArgs"]}');
  // Config.logger.i('tArgs: ${template["tArgs"]}');

  // FIXME: initializing data to be done by each template
  if (optionsRest.isNotEmpty && (Config.options.command == null)) {
    var libName = optionsRest[0];

    Config.libPkgRoot = await resolvePkgRoot(libName);

    if ( !verifyExists(Config.libPkgRoot + '/templates/' + template['template'])) {
      Config.prodLogger.e('Template ${template["template"]} not found in library $libName');
      exit(0);
    }

    switch (libName) {
      case 'dartrix':
        dispatchBuiltin(template['template'], Config.options,
            template['dartrixArgs'], template['tArgs']); // optionsRest);
        break;
      default:
        await dispatchPlugin(libName, template['template'], Config.options,
            template['dartrixArgs'], template['tArgs']); // optionsRest);
      // Config.options, optionsRest);
      // Config.options['template'],
      // template['template'],
      // template['tArgs']);
      // (Config.options.command == null)
      //     ? null
      //     : Config.options.command.arguments);
    }
  }
}
// if (libName.startsWith('pkg:')) {
//   print('PKG');
//   await dispatchPlugin(
//       libName,
//       Config.options['template'],
//       (Config.options.command == null)
//           ? null
//           : Config.options.command.arguments);
//   exit(0);
// } else {
//   if (libName.startsWith('package:')) {
//     print('PACKAGE');
//     exit(0);
//   } else {
//     if (libName.startsWith('path:')) {
//       print('PATH');
//       exit(0);
//     } else {
//       Config.logger.e('Unrecognized param: $libName. Did you forget -t?');
//       exit(0);
//     }
//   }
// }
// }

// if (tData['plugin'] != null) {
//   dispatchPlugin(tData['plugin'], template,
//     (Config.options.command == null)? null : Config.options.command.arguments);
// } else {
//FIXME: we don't need to list all, just get the one we want!
// await initBuiltinTemplates();
// if ( builtinTemplates.keys.contains(template) ) {
//   Config.logger.i('FIXME: run builtin');
//     (Config.options.command == null)? null : Config.options.command.arguments);
// } else {
//   Config.logger.d('EXCEPTION: template $template not found.');
//   exit(0);
// }
// }
// Config.logger.d('script locn: ${Platform.script.toString()}');
// Config.logger.d('built-ins: $builtinTemplates');

// String inDir = getInDir(Config.options['template']);
// Config.logger.d('inDir: $inDir');

// getResource('hello_template');

// if (template == 'plugin')
// transformDirectory(inDir, outPathPrefix, tData);
// }
