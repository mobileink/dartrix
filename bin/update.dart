// update template project under development. generate manpages, docstrings,
// handlers.
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

//import 'package:dartrix_lib/dartrix_lib.dart';

import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/handler_template.dart';
import 'package:dartrix/src/utils.dart';

var _log = Logger('list');

String manTemplate = """
.Dd March 18, 2020
.Dt {{LIB}}_DARTRIX
.Sh NAME
.Nm {{template}}
.Nd {{template}} template from package:{{package}}_dartrix
.Sh SYNOPSIS
Passed as an arg to dartrix:new -x package:{{package}}_dartrix,
.Nm {{template}}
.Op Fl c Ar param
.Sh DESCRIPTION
.Pp
The
.Em {{template}}
parameters are:
.Bl -tag -width Ds
.It Ar param1
Description of param 1 ...
.Pp
Default: param1-default
.El
.Sh EXAMPLES
Example goes here...
.Sh SEE ALSO
.Xr hello
""";

List templates;
Set<String> templateSet;

void listTemplates(ArgResults options) async {
  // print("listTemplates ${options.arguments}");
  templates = Directory(Directory.current.path + "/lib/templates").listSync();
  templates.retainWhere((f) => f is Directory);
  templateSet = templates.map((t)=>path.basename(t.path)).toSet();

  // print("Builtin templates:");
  // templates.forEach((t) {
  //     var tName = path.basename(t.path);
  //     String docString;
  //     // try {
  //     // docString = File(templatesRoot + "/" + tName + ".docstring")
  //     // .readAsStringSync();
  //     // } on FileSystemException {
  //     //   // if (debug.debug)
  //     //   // _log.info("docstring not found for ${builtin.path}");
  //     //   if (debug.debug) {
  //     //     docString = warningPen("${tName}.docstring not found");
  //     //     // tName = warningPen(sprintf("%-18s", [tName]));
  //     //   }
  //     // }
  //     tName = sprintf("%-18s", [tName]);
  //     print("\t${tName}"); // ${docString}");
  // });
}

void updateDocstrings() {
  // _log.info("updateDocstrings");
  var package = path.basename(Directory.current.path);
  package = package.replaceAll(RegExp(r"_dartrix$"), '');
  var templates = Directory(Directory.current.path + "/lib/templates").listSync();
  var docstrings = List.from(templates);
  RegExp dsext = RegExp(r'\.docstring$');
  templates.removeWhere((fse) {
      return (fse is File);
  });
  // templates.forEach((fse) => print("tp: ${fse.path}"));

  docstrings.retainWhere((fse) {
      return dsext.hasMatch(fse.path);
  });
  // docstrings.forEach((fse) => print("ds: ${fse.path}"));

  var dsbases = docstrings.map((ds)
    => (ds.path).replaceAll(RegExp(r'.docstring$'), ''));
  // dsbases.forEach((ds) => print("dsb: ${ds}"));

  // Set<String> templateSet = templates.map((t) => path.basename(t.path)).toSet();
  Set<String> dsSet = dsbases.map((ds) => path.basename(ds)).toSet();

  Set<String> orphanedDocstrings = dsSet.difference(templateSet);
  Set<String> missingDocstrings = templateSet.difference(dsSet);

  if (debug.verbose) {
    if (orphanedDocstrings.isNotEmpty) {
      _log.warning("docstrings without corresponding templates: $orphanedDocstrings");
    }
  }
  if (missingDocstrings.isNotEmpty) {
    if (debug.verbose) _log.warning("missing docstrings: $missingDocstrings");
    missingDocstrings.forEach((ds) {
        String fname = Directory.current.path + "/lib/templates/" + ds + ".docstring";
        // double-check to ensure no overwrites:
        // var exists = FileSystemEntity.typeSync(fname);
        // if (exists != FileSystemEntityType.notFound) {
        //   _log.severe("$fname already exists");
        //   exit(0);
        // }

        // write docstring
        Map data = {
          "template": ds
        };
        var dsTemplate = "{{template}} docstring";
        var template = Template(dsTemplate, name: "hardcoded", htmlEscapeValues: false);
        var contents = template.renderString(data);
        File(fname).writeAsStringSync(contents);
        _log.info("wrote $fname");
    });
  }

}

/// Update template handlers in lib/src
void updateHandlers() {
  _log.info("updateHandlers");
  var package = path.basename(Directory.current.path);
  package = package.replaceAll(RegExp(r"_dartrix$"), '');
  var handlers = Directory(Directory.current.path + "/lib/src").listSync();
  RegExp dartExt = RegExp(r'\.dart$');
  handlers.retainWhere((fse) {
      return dartExt.hasMatch(fse.path);
  });
  // handlers.forEach((h) => print(h.path));
  var handlerSet = handlers.map((h)
    => path.basenameWithoutExtension(h.path)
  ).toSet();
  _log.info("hset: $handlerSet");
  _log.info("tpset: $templateSet");

  Set<String> orphanedHandlers = handlerSet.difference(templateSet);
  if (debug.verbose) {
    if (orphanedHandlers.isNotEmpty) {
      _log.warning("manpages without corresponding templates: $orphanedHandlers");
    }
  }

  var missingHandlers = templateSet.difference(handlerSet);
  if (debug.verbose) {
    if (missingHandlers.isNotEmpty) {
      _log.info("missing handlers: $missingHandlers");
    }
  }
  missingHandlers.forEach((h) {
      String fname = Directory.current.path + "/lib/src/" + h + ".dart";
      // double-check to ensure no overwrites:
      // var exists = FileSystemEntity.typeSync(fname);
      // if (exists != FileSystemEntityType.notFound) {
      //   _log.severe("$fname already exists");
      //   exit(0);
      // }

      // write handler
      Map data = {
        "package" : package,
        "template": h,
        "Template": capitalize(h)
      };
      var template = Template(handlerTemplate, name: "hardcoded", htmlEscapeValues: false);
      var contents = template.renderString(data);
      File(fname).writeAsStringSync(contents);
      _log.info("wrote $fname");
  });
}

void updateManuals() {
  // _log.info("updateManuals");
  var package = path.basename(Directory.current.path);
  package = package.replaceAll(RegExp(r"_dartrix$"), '');
  var manpages = Directory(Directory.current.path + "/lib/man").listSync();
  RegExp manext = RegExp(r'\.[0-9][a-z]?$');
  manpages.retainWhere((fse) {
      return manext.hasMatch(fse.path);
  });
  // manpages.forEach((mp) => print(mp.path));
  var manpageSet = manpages.map((mp)
    => path.basenameWithoutExtension(mp.path)
  ).toSet();
  // _log.info("mpset: $manpageSet");
  // Set<String> templateSet = templates.map((t)=>path.basename(t.path)).toSet();
  // _log.info("tpset: $templateSet");

  Set<String> orphanedManpages = manpageSet.difference(templateSet);
  if (debug.verbose) {
    if (orphanedManpages.isNotEmpty) {
      _log.warning("manpages without corresponding templates: $orphanedManpages");
    }
  }

  var missingManpages = templateSet.difference(manpageSet);
  if (debug.verbose) {
    if (missingManpages.isNotEmpty) {
      _log.warning("missing manpages: $missingManpages");
    }
  }
  missingManpages.forEach((mp) {
      String fname = Directory.current.path + "/lib/man/" + mp + ".1";
      // double-check to ensure no overwrites:
      var exists = FileSystemEntity.typeSync(fname);
      if (exists != FileSystemEntityType.notFound) {
        _log.severe("$fname already exists");
        exit(0);
      }

      // write manpage
      Map data = {
        "package" : package,
        "LIB": package.toUpperCase(),
        "template": mp
      };
      var template = Template(manTemplate, name: "man", htmlEscapeValues: false);
      var contents = template.renderString(data);
      File(fname).writeAsStringSync(contents);
      _log.info("wrote $fname");
  });
}

void printUsage(ArgParser argParser) async {
  print("dartrix:update, version 0.1.0");
  print("Update template project: generate missing manpages, docstrings, handlers for current package.\n");
  print("Usage: pub global run dartrix:update [hv] [--debug]\n");
  print(argParser.usage);
  print("");
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
  sanityCheck();
  listTemplates(options);
  updateDocstrings();
  updateManuals();
  updateHandlers();
}
