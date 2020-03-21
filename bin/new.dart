import 'dart:core';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
// import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/which.dart';
import 'package:strings/strings.dart';

import 'package:dartrix/dartrix.dart';
import 'package:dartrix/src/builtins.dart';
import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
// import 'package:dartrix/src/plugins.dart';
import 'package:dartrix/src/utils.dart';

var _log = Logger('new');

// final myScratchSpaceResource =
//     new Resource(() => ScratchSpace());

String http_parser_pkg = 'package:http_parser';
String hello_pkg = 'package:hello_template';

void validateSnakeCase(String pkg) {
  final r = RegExp(r'^[a-z_][a-z0-9_]*$');
  if (!r.hasMatch(pkg)) {
    _log.warning('Invalid name (snake_case): $pkg');
    exit(0);
  }
}

void validateCamelCase(String name) {
  final r = RegExp(r'^[A-Z][A-Za-z0-9_]*$');
  if (!r.hasMatch(name)) {
    _log.warning('Invalid name (CamelCase): $name');
    exit(0);
  }
}

void validateTemplateName(String t) {
  validateSnakeCase(t);
}

// String getInDir(String template) {

//   // If template is built-in, proceed, else call resolution fn

//   String p = path.prettyUri(Platform.script.toString());
//   // _log.finer('inDir 1: $p');
//   String inDir = path.dirname(p) + '/..';
//   var inPfx = path.canonicalize(inDir);
//   // _log.finer('inPfx 2: $inPfx');
//   if (template == 'split-plugin') {
//     inDir = inPfx + '/mustache/plugins/greetings-services';
//   } else {
//     inDir = inPfx + '/mustache/plugins/greetings';
//   }
// }

void printUsage(ArgParser argParser) {
  print('\n\t\tDartrix Templating System - "new" command\n');
  print('Usage:');
  print('  Builtins: pub global run dartrix:new [ordpcfhvt]\n');
  print(
      '  Plugins: pub global run dartrix:new [ordpcfv] plugin [th][toptions]\n');
  print(
      '\t plugin:  pkg:package_name | package:package_name | path:path/to/package_name\n');
  print('\t toptions:  per template; pass -h or use dartrix:man to view.\n');
  print('Options:');
  print(argParser.usage);

  print(
      '\nTo list available commands and templates: pub global run dartrix:list\n');
  // print('\nBuiltin templates:');
  // print('\tplugin');
  // print('\tsplitplugin');
  // print('\tapp-dart');
  // print('\tapp-flutter');
  // print('\tpackage');
  // print('\tlib');
  // print('\ttool\n');
  // print('Other commands:\n');
  // // print('\tdartrix:dev\t\tDocumentation for template development\n');
  // print('\tdartrix:list\t\tList available template libraries');
  // print('\tdartrix:man\t\tDisplay manual pages\n');
}

void main(List<String> args) async {
  Config.config('dartrix');
  Logger.root.level = Level.ALL;
  Logger.root
    ..onRecord.listen((record) {
      var level;
      switch (record.level.name) {
        case 'SHOUT':
          level = shoutPen(record.level.name);
          break;
        case 'SEVERE':
          level = severePen(record.level.name);
          break;
        case 'WARNING':
          level = warningPen(record.level.name);
          break;
        case 'INFO':
          level = infoPen(record.level.name);
          break;
        case 'CONFIG':
          level = configPen(record.level.name);
          break;
        default:
          level = record.level.name;
          break;
      }
      print('${record.loggerName} ${level}: ${record.message}');
    });

  Config.argParser = ArgParser(allowTrailingOptions: true);
  Config.argParser.addOption(
    'template', abbr: 't', // defaultsTo: 'hello',
    valueHelp: '[a-z][a-z0-9_]*',
    help: 'Template name.',
    // callback: (t) => validateTemplateName(t)
  );
  Config.argParser.addOption('root',
      abbr: 'r',
      valueHelp: 'directory, without "/".',
      help:
          'Root output segment.  Defaults to value of --package arg (i.e. "hello").'
      // callback: (pkg) => validateSnakeCase(pkg)
      );
  Config.argParser.addOption('domain',
      abbr: 'd',
      defaultsTo: 'example.org',
      help:
          'Domain name. Must be legal as a Java package name;\ne.g. must not begin with a number, or match a Java keyword.',
      valueHelp: 'segmented.domain.name');
  Config.argParser.addOption('package',
      abbr: 'p',
      defaultsTo: 'hello',
      valueHelp: '[_a-z][a-z0-9_]*',
      help: 'snake_cased name.  Used e.g. as Dart package name.',
      callback: (pkg) => validateSnakeCase(pkg));
  Config.argParser.addOption('class',
      abbr: 'c',
      defaultsTo: 'Hello',
      valueHelp: '[A-Z][a-zA-Z0-9_]*',
      help:
          'CamelCased name. Used as class/type name for Java, Kotline, etc.\nDefaults to --package value, CamelCased (i.e. "Hello").\nE.g. -p foo_bar => -c FooBar.',
      callback: (name) => validateCamelCase(name));
  Config.argParser.addOption('out',
      abbr: 'o',
      defaultsTo: './',
      help: 'Output path.  Prefixed to --root dir.',
      valueHelp: 'path.');
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
  Config.argParser.addFlag('dry-run', abbr: 'n', defaultsTo: false);
  Config.argParser.addFlag('force', abbr: 'f', defaultsTo: false);
  Config.argParser.addFlag('help', abbr: 'h', defaultsTo: false);
  Config.argParser.addFlag('debug', defaultsTo: false);
  Config.argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);

  // Config.argParser.addFlag('manpage', defaultsTo: false);

  var pluginCmd = ArgParser.allowAnything();
  Config.argParser.addCommand('pkg:', pluginCmd);
  // var packageCmd = ArgParser.allowAnything();
  Config.argParser.addCommand('package:', pluginCmd);
  // var pathCmd = ArgParser.allowAnything();
  Config.argParser.addCommand('path:', pluginCmd);

  try {
    Config.options = Config.argParser.parse(args);
  } catch (e) {
    _log.severe(e);
    exit(0);
  }

  if (args.isEmpty) {
    printUsage(Config.argParser);
    exit(0);
  }

  if (Config.options['debug']) debug.debug = true;

  if (debug.debug) debug.debugOptions();

  if (Config.options['help']) {
    // print('h: ${args.indexOf('-h')}');
    // print('help: ${args.indexOf('--help')}');
    // print('t: ${args.indexOf('-t')}');
    // print('template: ${args.indexOf('--template')}');
    if (args.contains('-t') || args.contains('template')) {
      if (args.contains('-h') &&
          ((args.indexOf('-h') < args.indexOf('-t')) ||
              (args.indexOf('-h') < args.indexOf('--template')))) {
        printUsage(Config.argParser);
        exit(0);
      } else {
        if (args.contains('--help') &&
            ((args.indexOf('--help') < args.indexOf('-t')) ||
                (args.indexOf('--help') < args.indexOf('--template')))) {
          printUsage(Config.argParser);
          exit(0);
        }
      }
    }
  }

  // var cmd = Config.options.command;
  // _log.finer('cmd: $cmd');

  // var cmdOptions;
  // if (Config.options.command != null) {
  //   cmdOptions = pluginCmd.parse(Config.options.command.arguments);
  //   // _log.finer('command: ${Config.options.command.name}');
  //   // _log.finer('command args: ${Config.options.command.arguments}');
  //   // _log.finer('command opts: ${Config.options.command.options}');
  //   // _log.finer('command rest: ${Config.options.command.rest}');
  // }

  Config.verbose = Config.options['verbose'];

  tData['domain'] = Config.options['domain'];

  if (Config.options['root'] == null) {
    tData['segmap']['ROOTPATH'] = './';
  } else {
    tData['segmap']['ROOTPATH'] = Config.options['root'];
  }

  tData['package']['dart'] = Config.options['package'];
  // 'package.java' = Java package string, e.g. org.example.foo
  String dartPackage = Config.options['package'];
  String rdomain = tData['domain'].split('.').reversed.join('.');
  //String
  var javaPackage = rdomain + '.' + dartPackage;
  tData['package']['java'] = javaPackage;

  tData['segmap']['RDOMAINPATH'] = rdomain.replaceAll('.', '/');

  var pluginClass = (Config.options['class'] == 'Hello')
      ? dartPackage.split('_').map((s) => capitalize(s)).join()
      : Config.options['class'];

  tData['plugin-class'] = pluginClass;
  tData['class'] = pluginClass;
  tData['segmap']['CLASS'] = Config.options['class'];

  tData['root'] = Config.options['root'];
  tData['out'] = Config.options['out'];

  tData['dartrix']['force'] = Config.options['force'];

  // linux, macos, windows, android, ios, fuchsia
  tData['platform'] = Platform.operatingSystem;
  tData['segmap']['PLATFORM'] = Platform.operatingSystem;

  tData['segmap']['PKG'] = Config.options['package'];

  // Theses properties are for android/local.properties.
  // _log.finer('resolvedExecutable: ${Platform.resolvedExecutable}');
  // FIXME: find a better way?
  var androidExecutable = whichSync('android');
  // _log.finer('android exe: $androidExecutable');
  var androidSdk =
      path.joinAll(path.split(androidExecutable)..removeLast()..removeLast());
  tData['sdk']['android'] = androidSdk;

  var flutterExecutable = whichSync('flutter');
  // _log.finer('flutter exe: $flutterExecutable');
  var flutterSdk =
      path.joinAll(path.split(flutterExecutable)..removeLast()..removeLast());
  tData['sdk']['flutter'] = flutterSdk;

  // var outPathPrefix = Config.options['outpath'];
  // _log.finer('outPathPrefix: $outPathPrefix');

  // var rootDir = (Config.options['root'] == null)
  // ? '/'
  // : '/' + Config.options['root'];

  // var outPath = outPathPrefix + rootDir;

  // if (outPathPrefix != './') {
  //   if (Directory(outPath).existsSync()) {
  //     if ( !Config.options['force'] ) {
  //       _log.severe('Directory '$outPath' already exists. Use -f to force overwrite.');
  //       exit(0);
  //     }
  //     _log.warning('Overwriting plugins/$outPath.');
  //   }
  // }

  var template = Config.options['template'];
  tData['template'] = template;
  // tData['plugin'] = Config.options['plugin'];

  if (Config.options.rest.isNotEmpty && (Config.options.command == null)) {
    var pkgSpec = Config.options.rest[0];
    if (pkgSpec.startsWith('pkg:')) {
      print('PKG');
      exit(0);
    } else {
      if (pkgSpec.startsWith('package:')) {
        print('PACKAGE');
        exit(0);
      } else {
        if (pkgSpec.startsWith('patn:')) {
          print('PATH');
          exit(0);
        } else {
          _log.severe('Unrecognized param: $pkgSpec. Exiting.');
          exit(0);
        }
      }
    }
  }

  // if (tData['plugin'] != null) {
  //   generateFromPlugin(tData['plugin'], template,
  //     (Config.options.command == null)? null : Config.options.command.arguments);
  // } else {
  //FIXME: we don't need to list all, just get the one we want!
  // await initBuiltinTemplates();
  // if ( builtinTemplates.keys.contains(template) ) {
  //   _log.info('FIXME: run builtin');
  dispatchBuiltin(template);
  //     (Config.options.command == null)? null : Config.options.command.arguments);
  // } else {
  //   _log.finer('EXCEPTION: template $template not found.');
  //   exit(0);
  // }
  // }
  // _log.finer('script locn: ${Platform.script.toString()}');
  // _log.finer('built-ins: $builtinTemplates');

  // String inDir = getInDir(Config.options['template']);
  // _log.finer('inDir: $inDir');

  // getResource('hello_template');

  // if (template == 'plugin')
  // transformDirectory(inDir, outPathPrefix, tData);
}
