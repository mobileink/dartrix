import 'dart:core';
import 'dart:io';
// import 'dart:isolate';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:sprintf/sprintf.dart';

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/builtins.dart';
import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/utils.dart';

void listBuiltins(ArgResults options) async {
  // print('listBuiltins ${options.arguments}');
  //Uri
  // var packageConfigUri = await Isolate.packageConfig;
  // // e.g. file:///Users/gar/mobileink/dartrix/.packages
  // if (Config.debug) {
  //   Config.logger.i('packageConfigUri $packageConfigUri');
  // }

  // WARNING: for pub global activateds, the current dir of the script contains
  // .packages, which is the value of Isolate.packageConfig, but it does NOT
  // contain all of the subdirs of the original pkg root. It only the bin dir,
  // plus the pub stuff (.dart_tool, .packages, pubspec.lock).  So to find the
  // templates/ dir, we have to look it up in the .packages file using
  // findPackageConfigUri

  // this is a v1 pkg config, i.e. a .packages file, so back up one segment:
  // String libDir = path.dirname(packageConfigUri.path);
  // var templatesRoot = path.dirname(packageConfigUri.path) + '/templates';
  //List
  var templatesRoot = await getBuiltinTemplatesRoot();
  var templates = Directory(templatesRoot).listSync();
  templates.retainWhere((f) => f is Directory);
  print('Builtin templates:');
  templates.forEach((t) {
    var tName = path.basename(t.path);
    //String
    var docString;
    try {
      docString =
          File(templatesRoot + '/' + tName + '.docstring').readAsStringSync();
    } on FileSystemException {
      // if (debug.debug)
      // Config.logger.i('docstring not found for ${builtin.path}');
      if (debug.debug) {
        docString = warningPen('${tName}.docstring not found');
        // tName = warningPen(sprintf('%-18s', [tName]));
      }
    }
    tName = sprintf('%-18s', [tName]);
    print('\t${tName} ${docString}');
  });
}

void listPlugins(String lib, ArgResults options) async {
  // print('listPlugins');
  var lib = options.rest[0];
  //String
  var libDir = await resolvePkgRoot('package:' + lib + '_dartrix');
  if (Config.verbose) {
    Config.logger.i('resolved $lib to package:${lib}_dartrix to $libDir');
  }
  //String
  var templatesRoot = libDir + '/templates';
  //List
  var templates = Directory(templatesRoot).listSync();
  templates.retainWhere((f) => f is Directory);
  print('package:${lib}_dartrix templates:');
  templates.forEach((t) {
    var tName = path.basename(t.path);
    //String
    var docString;
    try {
      docString =
          File(templatesRoot + '/' + tName + '.docstring').readAsStringSync();
    } on FileSystemException {
      // if (debug.debug)
      // Config.logger.i('docstring not found for ${builtin.path}');
      if (debug.debug) {
        docString = warningPen('${tName}.docstring not found');
        // tName = warningPen(sprintf('%-18s', [tName]));
      }
    }
    tName = sprintf('%-18s', [tName]);
    print('\t${tName} ${docString}');
  });
}

void printUsage(ArgParser argParser) async {
  print('dartrix:list, version 0.1.0\n');
  print('Usage: pub global run dartrix:list [hv] [library]\n');
  // print('Options (for builtins and plugin libraries only):\n');
  print(argParser.usage);

  print('\nAvailable template libraries:');
  //List<Package>
  var pkgs = await getPlugins('_dartrix');
  print('\t${sprintf("%-18s", ["dartrix"])} Builtin templates');
  pkgs.forEach((pkg) {
    var pkgName = pkg.name.replaceFirst(RegExp('_dartrix\$'), '');
    var docString = getDocstring(pkg);
    pkgName = sprintf('%-18s', [pkgName]);
    print('\t${pkgName} ${docString}');
  });
  print('');
  print('\nOther Dartrix commands:');
  print('\tdartrix:list\t\t this command');
  print('\tdartrix:new\t\t generate new files from template');
  print('\tdartrix:man\t\t print dartrix manpages');
  print('\tdartrix:sanity\t\t sanity check (for template developers)');
  print('\tdartrix:update\t\t update template lib (for template developers)');

  // print('\tdartrix\t\tBuiltin templates. Optional; if no <libname> specified,');
  // print('\t\t\tthe -t option refers to a builtin template.');
  // print('\t<libname>\tDocumentation for template library plugin.\n');
  // print('where <libname> is the name part of a Dartrix plugin package; for');
  // print('example, the libname for package:greetings_dartrix is 'greetings.'\n');
}

void main(List<String> args) async {
  Config.config('dartrix');
  var argParser = ArgParser(usageLineLength: 120);
  // argParser.addOption('template', abbr: 't',
  //   valueHelp: '[a-z_][a-z0-9_]*',
  //   help: 'Template name.',
  //   // defaultsTo: 'plugin',
  //   // callback: (t) => validateTemplateName(t)
  // );
  argParser.addFlag('help', abbr: 'h', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('debug', defaultsTo: false);

  Config.options = argParser.parse(args);

  Config.verbose = Config.options['verbose'];
  debug.debug = Config.options['debug'];

  if (debug.debug) {
    debug.debugOptions();
    Config.debug = true;
  }

  // var root = path.dirname(Platform.script.toString());
  // print('proj root: $root');

  if (Config.options['help']) {
    await printUsage(argParser);
    exit(0);
  }

  if (Config.options.rest.isEmpty) {
    //listBuiltins(Config.options);
    printUsage(argParser);
  } else {
    switch (Config.options.rest[0]) {
      case 'dartrix':
        listBuiltins(Config.options);
        break;
      case 'help':
      case '-h':
      case '--help':
        await printUsage(argParser);
        exit(0);
        break;
      default:
        listPlugins(args[0], Config.options);
    }
  }
}
