// import 'dart:async';
import 'dart:io';
// import 'dart:isolate';

import 'package:args/args.dart';
// import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/generator.dart';
import 'package:dartrix/src/lister.dart';
import 'package:dartrix/src/plugins.dart';
// import 'package:dartrix/src/paths.dart';
// import 'package:dartrix/src/utils.dart';

import 'package:dartrix/src/handlers/dart_cmdsuite.dart';
import 'package:dartrix/src/handlers/bashrc.dart';

// void dispatchPlugin(String pkg, String template, List<String> args) async {
//   // Config.debugLogger.v('dispatchPlugin: $pkg, $template, $args');

//FIXME: this should go in the command
void printLibOptions(String tlib) {
  switch (tlib) {
    case ':dartrix':
    print('Options for library :dartrix:');
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
void processArgs(String pkg, String template, ArgResults _options,
    List<String> libArgs, List<String> tArgs) async {
  // Config.debugLogger.v('processArgs $pkg, $template, $_options, $libArgs, $tArgs');
  // debug.debugArgResults(_options);
  if (_options.wasParsed('help') ||
      libArgs.contains('-h') ||
      libArgs.contains('--help') ||
      tArgs.contains('-h') ||
      tArgs.contains('--help')) {
    // printLibOptions(pkg);
    if (template == null) exit(0);
  }

  // var templates = await listTemplatesAsMap(Config.libPkgRoot);
  var templateSpec = await listTemplate(pkg, Config.libPkgRoot, template);
  // Config.ppLogger.v('processArgs result: $templateSpec');

  Config.templateRoot = Config.libPkgRoot +
      ((Config.libPkgRoot == '.') ? Config.hereDir : '/') +
      'templates/' +
      template;
  // Config.debugLogger.v('Config.templateRoot: ${Config.templateRoot}');

  await setTemplateArgs(Config.templateRoot, libArgs, tArgs); // args);

  Config.templateRoot = path.canonicalize(templateSpec['rootUri']);
}

// FIXME: _options == Config.options
void dispatchBuiltin(String template, ArgResults _options,
    List<String> dartrixArgs, List<String> tArgs) async {
  // Config.debugLogger.d('dispatchBuiltin $template');
  // print('option args: ${_options.arguments}');
  // print('option rest: ${_options.rest}');

  await processArgs(':dartrix', template, _options, dartrixArgs, tArgs);

  await processTemplate();

}

void dispatchHere(String template, ArgResults _options, List<String> userArgs,    List<String> tArgs) async {
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
    Config.prodLogger.e('template $template not found in lib :here');
  }
}

void dispatchLocal(String template, ArgResults _options, List<String> userArgs,
    List<String> tArgs) async {
  Config.ppLogger.v('dispatchLocal $template, $_options, $userArgs, $tArgs');

  await processArgs(':local', template, _options, userArgs, tArgs);
  var templates = await listTemplatesAsMap(Config.local);

 if (templates.keys.contains(template)) {
    spawnCallback({});
  } else {
    Config.prodLogger.e('template $template not found in lib :local');
  }
}

// FIXME: _options == Config.options
void dispatchPlugin(String pkg, String template, ArgResults _options,
    List<String> pluginArgs, List<String> tArgs) async {
  // Config.ppLogger.v('dispatchPlugin $pkg, $template, $_options, $pluginArgs, $tArgs');

  await processArgs(pkg, template, _options, pluginArgs, tArgs);

  // if (shouldSpawn(template)) { // read spawn: key of yaml
  // } else {
  // }

  if (findLibMain(pkg)) {
    await spawnPluginFromPackage(
        spawnCallback, externalOnDone, pkg, [template, ...?tArgs]);
  } else {
    // spawnCallback({});
    await processTemplate();
  }
}

void dispatchUser(String template, ArgResults _options, List<String> userArgs,
    List<String> tArgs) async {
  // Config.ppLogger.v('dispatchUser $template, $_options, $userArgs, $tArgs');

  await processArgs(':home', template, _options, userArgs, tArgs);
  var templates = await listTemplatesAsMap(Config.home + '/.dartrix.d');
  if (templates.keys.contains(template)) {
    // spawnCallback({});
    await processTemplate();
  } else {
    Config.prodLogger.e('template $template not found in lib :user');
  }
}
