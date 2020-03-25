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

void main(List<String> args) async {
  Config.config('dartrix');

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

  if (Config.options['dry-run'] ||
      optionsRest.contains('--dry-run')) {
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

  if (Config.options['help'] ||
      optionsRest.contains('-h') ||
      optionsRest.contains('--help')) {
    await printUsage(Config.argParser);
    optionsRest.add('-h');
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

  // var cmdOptions;
  // if (Config.options.command != null) {
  //   cmdOptions = pluginCmd.parse(Config.options.command.arguments);
  //   // Config.logger.d('command: ${Config.options.command.name}');
  //   // Config.logger.d('command args: ${Config.options.command.arguments}');
  //   // Config.logger.d('command opts: ${Config.options.command.options}');
  //   // Config.logger.d('command rest: ${Config.options.command.rest}');
  // }

  // 'package.java' = Java package string, e.g. org.example.foo
  // String dartPackage = Config.options['package'];

  // FIXME: initializing data to be done by each template
  if (optionsRest.isNotEmpty && (Config.options.command == null)) {
    var pkgSpec = optionsRest[0];

    // if (Config.options['template'] == null) {
    //   Config.logger.e('Missing template parameter; did you forget -t ?');
    //   exit(0);
    // }

    switch (pkgSpec) {
      case 'dartrix':
        dispatchBuiltin(Config.options, optionsRest);
        break;
      default:
        await generateFromPlugin(
            pkgSpec,
            Config.options['template'],
            (Config.options.command == null)
                ? null
                : Config.options.command.arguments);
    }
  }
}
// if (pkgSpec.startsWith('pkg:')) {
//   print('PKG');
//   await generateFromPlugin(
//       pkgSpec,
//       Config.options['template'],
//       (Config.options.command == null)
//           ? null
//           : Config.options.command.arguments);
//   exit(0);
// } else {
//   if (pkgSpec.startsWith('package:')) {
//     print('PACKAGE');
//     exit(0);
//   } else {
//     if (pkgSpec.startsWith('path:')) {
//       print('PATH');
//       exit(0);
//     } else {
//       Config.logger.e('Unrecognized param: $pkgSpec. Did you forget -t?');
//       exit(0);
//     }
//   }
// }
// }

// if (tData['plugin'] != null) {
//   generateFromPlugin(tData['plugin'], template,
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
