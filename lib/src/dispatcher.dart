// import 'dart:async';
import 'dart:io';
// import 'dart:isolate';

import 'package:args/args.dart';
// import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
// import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/generator.dart';
import 'package:dartrix/src/lister.dart';
import 'package:dartrix/src/plugins.dart';
// import 'package:dartrix/src/paths.dart';
// import 'package:dartrix/src/utils.dart';

// import 'package:dartrix/src/handlers/dart_cmdsuite.dart';
// import 'package:dartrix/src/handlers/bashrc.dart';

// void dispatchPlugin(String pkg, String template, List<String> args) async {
//   // Config.debugLogger.v('dispatchPlugin: $pkg, $template, $args');

//FIXME: this should go in the command
void printLibOptions(String tlib) {
  switch (tlib) {
    case ':dartrix':
      print('Library :dartrix options:');
      print('--here\tPut output in ./.templates');
      break;
    case ':here':
      break;
    case ':user':
      break;
    case ':lib':
      break;
    default:
  }
}

// FIXME: _options == Config.options
void processArgs(String tLib, String template, ArgResults _options,
    List libArgs, List tArgs) async {
  // Config.debugLogger.v('processArgs $tLib, $template, $_options, $libArgs, $tArgs');
  // debug.debugArgResults(_options);
  if (_options.wasParsed('help') ||
      libArgs.contains('-h') ||
      libArgs.contains('--help') ||
      tArgs.contains('-h') ||
      tArgs.contains('--help')) {
    // printLibOptions(tLib);
    if (template == null) exit(0);
  }

  var templateSpec = await listTemplate(tLib, Config.libPkgRoot, template);
  // Config.ppLogger.v('processArgs result: $templateSpec');

  Config.templateRoot = Config.libPkgRoot +
      ((Config.libPkgRoot == '.') ? Config.hereDir : '/') +
      'templates/' +
      template;
  // Config.debugLogger.v('Config.templateRoot: ${Config.templateRoot}');

  await setTemplateArgs(tLib, Config.templateRoot, libArgs, tArgs); // args);
  // print('''63b63492-88c6-49c5-a223-d619cffb6123:  ''');
  // debug.debugConfig();

  Config.templateRoot = path.canonicalize(templateSpec['rootUri']);
}

// FIXME: _options == Config.options
void dispatchBuiltin(String template, ArgResults _options,
    List dartrixArgs, List tArgs) async {
  // Config.debugLogger.d('dispatchBuiltin $template');
  // print('option args: ${_options.arguments}');
  // print('option rest: ${_options.rest}');

  await processArgs(':dartrix', template, _options, dartrixArgs, tArgs);

  await processTemplate();
}

void dispatchHere(String template, ArgResults _options, List userArgs,
    List tArgs) async {
  // Config.ppLogger.v('dispatchHere $template, $_options, $userArgs, $tArgs');

  await processArgs(':here', template, _options, userArgs, tArgs);

  // var templates = await listTemplatesAsMap('./');
  // var templates = await listHereTemplates();
  var templates = await listTemplates(':here');

  // print('here templates: $templates');
  var tNames = templates.map((t) => t['name']);

  if (tNames.contains(template)) {
    // spawnCallback({});
    await processTemplate();
  } else {
    Config.prodLogger.e('template \':here $template\' not found.');
  }
}

void dispatchLocal(String template, ArgResults _options, List<String> userArgs,
    List<String> tArgs) async {
  // Config.ppLogger.v('dispatchLocal $template, $_options, $userArgs, $tArgs');

  await processArgs(':local', template, _options, userArgs, tArgs);

  await processTemplate();
}

// FIXME: _options == Config.options
void dispatchPlugin(String tLib, String template, ArgResults _options,
    List pluginArgs, List<String> tArgs) async {
  // Config.ppLogger.v('dispatchPlugin $tLib, $template, $_options, $pluginArgs, $tArgs');

  await processArgs(tLib, template, _options, pluginArgs, tArgs);

  // if (shouldSpawn(template)) { // read spawn: key of yaml
  // } else {
  // }

  if (findLibMain(tLib)) {
    await spawnPluginFromPackage(
        spawnCallback, externalOnDone, tLib, [template, ...?tArgs]);
  } else {
    // spawnCallback({});
    await processTemplate();
  }
}

void dispatchUser(String template, ArgResults _options, List<String> userArgs,
    List<String> tArgs) async {
  // Config.ppLogger.v('dispatchUser $template, $_options, $userArgs, $tArgs');

  await processArgs(':home', template, _options, userArgs, tArgs);

  await processTemplate();
}
