import 'dart:io';

import 'package:args/args.dart';
// import 'package:args/command_runner.dart';
// import 'package:path/path.dart' as path;
// import 'package:process_run/which.dart';
// import 'package:strings/strings.dart';

import 'package:dartrix/dartrix.dart';
// import 'package:dartrix/src/builtins.dart';
import 'package:dartrix/src/config.dart';
// import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/dispatcher.dart';
// import 'package:dartrix/src/paths.dart';
// import 'package:dartrix/src/plugins.dart';
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
  // List<String>
  var libArgs = [];
  // List<String>
  var tArgs = [];
  String template;

  // var ft;
  var tlib = subArgs[0];
  if (tlib.startsWith(':')) {
    libArgs.add(tlib);
    subArgs = subArgs.sublist(1);
    template = subArgs[0];
    if (template == '--help') {
      // print help for tlib, if any
      exit(0);
    }
    if ( + templateArgs['template'];
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
