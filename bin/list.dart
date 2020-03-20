import 'dart:async';
import 'dart:core';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/which.dart';
import 'package:sprintf/sprintf.dart';
import 'package:strings/strings.dart';

import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/resolver.dart';
import 'package:dartrix/src/utils.dart';

var _log = Logger('list');

void listBuiltins(ArgResults options) async {
  // print("listBuiltins ${options.arguments}");
  Uri packageConfigUri = await Isolate.packageConfig;
  // _log.info("packageConfigUri $packageConfigUri");
  // this is a v1 pkg config, i.e. a .packages file, so back up one segment:
  String libDir = path.dirname(packageConfigUri.path);
  var templatesRoot = path.dirname(packageConfigUri.path) + "/templates";
  List templates = Directory(templatesRoot).listSync();
  templates.retainWhere((f) => f is Directory);
  print("Builtin templates:");
  templates.forEach((t) {
      var tName = path.basename(t.path);
      // var spacer =
      // tName.length < 5
      // ? "\t\t"
      // : tName.length < 10
      // ? "\t\t"
      // : "\t";
      // spacer = tName.length < 8 ? spacer + "\t" : spacer;
      String docString;
      try {
      docString = File(templatesRoot + "/" + tName + ".docstring")
      .readAsStringSync();
      } on FileSystemException {
        // if (debug.debug)
        // _log.info("docstring not found for ${builtin.path}");
        if (debug.debug) {
          docString = warningPen("${tName}.docstring not found");
          // tName = warningPen(sprintf("%-18s", [tName]));
        }
      }
      tName = sprintf("%-18s", [tName]);
      print("\t${tName} ${docString}");
  });
}

void listPlugins(ArgResults options) async {
  print("listPlugins");
  var lib = options.rest[0];
  var libDir = await resolvePkgRoot("package:" + lib + "_dartrix");
  if (debug.verbose) _log.info("resolved $lib to package:${lib}_dartrix to $libDir");
  // var template = options['template'];
  // printManpage(lib, libDir, template);
}

void printUsage(ArgParser argParser) async {
  print("dartrix:list, version 0.1.0\n");
  print("Usage: pub global run dartrix:list [hv] [library]\n");
  // print("Options (for builtins and plugin libraries only):\n");
  print(argParser.usage);

  print("\nAvailable template libraries:");
  List<Package> pkgs = await getPlugins("_dartrix");
  print("\tdartrix\t\tBuiltin templates");
  pkgs.forEach((pkg) {
      var pkgName = pkg.name.replaceFirst(RegExp('_dartrix\$'),'');
      var spacer = pkgName.length < 8 ? "\t\t" : "\t";
      var docString = getDocstring(pkg);
      print("\t${pkgName}${spacer}${docString}");
  });
  print("");
  // print("\tdartrix\t\tBuiltin templates. Optional; if no <libname> specified,");
  // print("\t\t\tthe -t option refers to a builtin template.");
  // print("\t<libname>\tDocumentation for template library plugin.\n");
  // print("where <libname> is the name part of a Dartrix plugin package; for");
  // print("example, the libname for package:greetings_dartrix is 'greetings.'\n");
}

void main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root..onRecord.listen((record) {
      var level;
      switch (record.level.name) {
        case 'SHOUT': level = shoutPen(record.level.name); break;
        case 'SEVERE': level = severePen(record.level.name); break;
        case 'WARNING': level = warningPen(record.level.name); break;
        case 'INFO': level = infoPen(record.level.name); break;
        case 'CONFIG': level = configPen(record.level.name); break;
        default: level = record.level.name; break;
      }
      print('${record.loggerName} ${level}: ${record.message}');
  });

  var argParser = ArgParser(usageLineLength: 120);
  // argParser.addOption('template', abbr: 't',
  //   valueHelp: "[a-z_][a-z0-9_]*",
  //   help: "Template name.",
  //   // defaultsTo: 'plugin',
  //   // callback: (t) => validateTemplateName(t)
  // );
  argParser.addFlag('help', abbr: 'h', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('debug', defaultsTo: false);

  options = argParser.parse(args);

  debug.verbose = options['verbose'];
  debug.debug   = options['debug'];

  if (debug.debug) debug.debugOptions();

  // var root = path.dirname(Platform.script.toString());
  // print("proj root: $root");

  if (options['help']) {
    await printUsage(argParser);
    exit(0);
  }

  if (options.rest.isEmpty) {
    //listBuiltins(options);
    printUsage(argParser);
  } else {
    switch (options.rest[0]) {
      case "dartrix": listBuiltins(options); break;
      case "help":
      case "-h":
      case "--help": await printUsage(argParser); exit(0); break;
      default: listPlugins(options);
    }
  }
}
