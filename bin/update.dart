// update template project under development. generate manpages, docstrings,
// handlers.
// import 'dart:async';
import 'dart:core';
// import 'dart:convert';
import 'dart:io';
// import 'dart:isolate';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:mustache_template/mustache_template.dart';
// import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
// import 'package:process_run/which.dart';
// import 'package:sprintf/sprintf.dart';
import 'package:strings/strings.dart';

//import 'package:dartrix/dartrix.dart';

// import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/handler_template.dart';
import 'package:dartrix/src/utils.dart';

var _log = Logger('list');

String manTemplate = '''
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
''';

List templates;
Set<String> templateSet;

void listTemplates(ArgResults options) async {
  // print('listTemplates ${options.arguments}');
  templates = Directory(Directory.current.path + '/templates').listSync();
  templates.retainWhere((f) => f is Directory);
  templateSet = templates.map((t) => path.basename(t.path)).toSet();

  // print('Builtin templates:');
  // templates.forEach((t) {
  //     var tName = path.basename(t.path);
  //     String docString;
  //     // try {
  //     // docString = File(templatesRoot + '/' + tName + '.docstring')
  //     // .readAsStringSync();
  //     // } on FileSystemException {
  //     //   // if (debug.debug)
  //     //   // Config.logger.i('docstring not found for ${builtin.path}');
  //     //   if (debug.debug) {
  //     //     docString = warningPen('${tName}.docstring not found');
  //     //     // tName = warningPen(sprintf('%-18s', [tName]));
  //     //   }
  //     // }
  //     tName = sprintf('%-18s', [tName]);
  //     print('\t${tName}'); // ${docString}');
  // });
}

void updateDocstrings() {
  // Config.logger.i('updateDocstrings');
  var package = path.basename(Directory.current.path);
  package = package.replaceAll(RegExp(r'_dartrix$'), '');
  var templates = Directory(Directory.current.path + '/templates').listSync();
  var docstrings = List.from(templates);
  //RegExp
  var dsext = RegExp(r'\.docstring$');
  templates.removeWhere((fse) {
    return (fse is File);
  });
  // templates.forEach((fse) => print('tp: ${fse.path}'));

  docstrings.retainWhere((fse) {
    return dsext.hasMatch(fse.path);
  });
  // docstrings.forEach((fse) => print('ds: ${fse.path}'));

  var dsbases =
      docstrings.map((ds) => (ds.path).replaceAll(RegExp(r'.docstring$'), ''));
  // dsbases.forEach((ds) => print('dsb: ${ds}'));

  // Set<String> templateSet = templates.map((t) => path.basename(t.path)).toSet();
  //Set<String>
  var dsSet = dsbases.map((ds) => path.basename(ds)).toSet();

  //Set<String>
  var orphanedDocstrings = dsSet.difference(templateSet);
  //Set<String>
  var missingDocstrings = templateSet.difference(dsSet);

  if (Config.verbose) {
    if (orphanedDocstrings.isNotEmpty) {
      Config.logger.w(
          'docstrings without corresponding templates: $orphanedDocstrings');
    }
  }
  if (missingDocstrings.isNotEmpty) {
    Config.logger.w('missing docstrings: $missingDocstrings');
    missingDocstrings.forEach((ds) {
      //String
      var fname = Directory.current.path + '/templates/' + ds + '.docstring';
      // double-check to ensure no overwrites:
      // var exists = FileSystemEntity.typeSync(fname);
      // if (exists != FileSystemEntityType.notFound) {
      //   Config.logger.e('$fname already exists');
      //   exit(0);
      // }

      // write docstring
      //Map
      var data = {'template': ds};
      var dsTemplate = '{{template}} docstring';
      var template =
          Template(dsTemplate, name: 'hardcoded', htmlEscapeValues: false);
      var contents = template.renderString(data);
      File(fname).writeAsStringSync(contents);
      Config.logger.i('wrote $fname');
    });
  }
}

/// Update template handlers in lib/src
void updateHandlers() {
  // Config.logger.i('updateHandlers');
  var package = path.basename(Directory.current.path);
  package = package.replaceAll(RegExp(r'_dartrix$'), '');
  var handlers = Directory(Directory.current.path + '/lib/src').listSync();
  //RegExp
  var dartExt = RegExp(r'\.dart$');
  handlers.retainWhere((fse) {
    return dartExt.hasMatch(fse.path);
  });
  // handlers.forEach((h) => print(h.path));
  var handlerSet =
      handlers.map((h) => path.basenameWithoutExtension(h.path)).toSet();
  // Config.logger.i('hset: $handlerSet');
  // Config.logger.i('tpset: $templateSet');

  //Set<String>
  var orphanedHandlers = handlerSet.difference(templateSet);
  // if (config.verbose) {
  if (orphanedHandlers.isNotEmpty) {
    Config.logger.w('handlers without corresponding templates: $orphanedHandlers');
  }
  // }

  var missingHandlers = templateSet.difference(handlerSet);
  // if (config.verbose) {
  if (missingHandlers.isNotEmpty) {
    Config.logger.i('missing handlers: $missingHandlers');
  }
  // }
  missingHandlers.forEach((h) {
    //String
    var fname = Directory.current.path + '/lib/src/' + h + '.dart';
    // double-check to ensure no overwrites:
    // var exists = FileSystemEntity.typeSync(fname);
    // if (exists != FileSystemEntityType.notFound) {
    //   Config.logger.e('$fname already exists');
    //   exit(0);
    // }

    // write handler
    //Map
    var data = {'package': package, 'template': h, 'Template': capitalize(h)};
    var template =
        Template(handlerTemplate, name: 'hardcoded', htmlEscapeValues: false);
    var contents = template.renderString(data);
    File(fname).writeAsStringSync(contents);
    Config.logger.i('wrote $fname');
  });
}

void updateManuals() {
  // Config.logger.i('updateManuals');
  var package = path.basename(Directory.current.path);
  package = package.replaceAll(RegExp(r'_dartrix$'), '');
  var manpages = Directory(Directory.current.path + '/man').listSync();
  //RegExp
  var manext = RegExp(r'\.[0-9][a-z]?$');
  manpages.retainWhere((fse) {
    return manext.hasMatch(fse.path);
  });
  // manpages.forEach((mp) => print(mp.path));
  var manpageSet =
      manpages.map((mp) => path.basenameWithoutExtension(mp.path)).toSet();
  // Config.logger.i('mpset: $manpageSet');
  // Set<String> templateSet = templates.map((t)=>path.basename(t.path)).toSet();
  // Config.logger.i('tpset: $templateSet');

  //Set<String>
  var orphanedManpages = manpageSet.difference(templateSet);
  // if (config.verbose) {
  if (orphanedManpages.isNotEmpty) {
    Config.logger.w('manpages without corresponding templates: $orphanedManpages');
  }
  // }

  var missingManpages = templateSet.difference(manpageSet);
  // if (config.verbose) {
  if (missingManpages.isNotEmpty) {
    Config.logger.w('missing manpages: $missingManpages');
  }
  // }
  missingManpages.forEach((mp) {
    //String
    var fname = Directory.current.path + '/man/' + mp + '.1';
    // double-check to ensure no overwrites:
    var exists = FileSystemEntity.typeSync(fname);
    if (exists != FileSystemEntityType.notFound) {
      Config.logger.e('$fname already exists');
      exit(0);
    }

    // write manpage
    //Map
    var data = {
      'package': package,
      'LIB': package.toUpperCase(),
      'template': mp
    };
    var template = Template(manTemplate, name: 'man', htmlEscapeValues: false);
    var contents = template.renderString(data);
    File(fname).writeAsStringSync(contents);
    Config.logger.i('wrote $fname');
  });
}

void printUsage(ArgParser argParser) async {
  print('dartrix:update, version 0.1.0');
  print(
      'Update template project: generate missing manpages, docstrings, handlers for current package.\n');
  print('Usage: pub global run dartrix:update [hv] [--debug]\n');
  print(argParser.usage);
  print('');
}

void main(List<String> args) async {
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

  if (debug.debug) debug.debugOptions();

  // var root = path.dirname(Platform.script.toString());
  // print('proj root: $root');

  if (Config.options['help']) {
    await printUsage(argParser);
    exit(0);
  }
  sanityCheck();
  listTemplates(Config.options);
  updateDocstrings();
  updateManuals();
  updateHandlers();
}
