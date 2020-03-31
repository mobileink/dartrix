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
    print('\nLibrary \'$pkg\' options:');
    if (template == null) exit(0);
  }

  var templates = await listTemplatesAsMap(Config.libPkgRoot);
  // Config.ppLogger.v('processArgs tps: $templates');

  Config.templateRoot = Config.libPkgRoot +
      ((Config.libPkgRoot == '.') ? '/.' : '/') +
      'templates/' +
      template;
  // Config.debugLogger.v('Config.templateRoot: ${Config.templateRoot}');

  await setTemplateArgs(Config.templateRoot, libArgs, tArgs); // args);

  Config.templateRoot = path.normalize(templates[template]['rootUri']);
}

// FIXME: _options == Config.options
void dispatchBuiltin(String template, ArgResults _options,
    List<String> dartrixArgs, List<String> tArgs) async {
  // Config.debugLogger.d('dispatchBuiltin');
  // print('option args: ${_options.arguments}');
  // print('option rest: ${_options.rest}');

  await processArgs('dartrix', template, _options, dartrixArgs, tArgs);

  var templates = await listTemplatesAsMap(null); // listBuiltinTemplates();
  // Config.ppLogger.v('bt: $templates, rtt: ${templates.runtimeType}');
  if (templates.keys.contains(template)) {
    //   // print('found template $template in lib');
    //   // debugging:
    //   // var pkg = templates[template];
    //   // Config.logger.i('pkg: $pkg, rtt: ${pkg.runtimeType}');
    //   // var r = pkg['root'];
    //   // Config.debugLogger.i('root: $r');

    //   Config.templateRoot = templates[template]['root'];

    //   await processYamlArgs(Config.templateRoot, tArgs);

    switch (template) {
      case 'bashrc':
        // await handleBashrc(templates[template]['root'], tArgs);
        await handleBashrc(Config.templateRoot, tArgs);
        break;
      case 'dart_cmdsuite':
        await handleDartCmdSuite(templates[template]['root'], tArgs);
        break;
      default:
        // Config.prodLogger.e('No handler for template $template');
        await generateFromBuiltin();
    }
  } else {
    Config.prodLogger.e('template $template not found in lib :dartrix');
  }
}

void dispatchHere(String template, ArgResults _options, List<String> userArgs,    List<String> tArgs) async {
  // Config.ppLogger.v('dispatchHere $template, $_options, $userArgs, $tArgs');

  await processArgs(':here', template, _options, userArgs, tArgs);
  // var templates = await listTemplatesAsMap('./');
  var templates = await listHereTemplates();
  print('here templates: $templates');
  var tNames = templates.map((t) => t['name']);
  
  if (tNames.contains(template)) {
    spawnCallback({});
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
    spawnCallback({});
  }
}

void dispatchUser(String template, ArgResults _options, List<String> userArgs,
    List<String> tArgs) async {
  Config.ppLogger.v('dispatchUser $template, $_options, $userArgs, $tArgs');

  await processArgs(':home', template, _options, userArgs, tArgs);
  var templates = await listTemplatesAsMap(Config.home + '/.dartrix.d');
  if (templates.keys.contains(template)) {
    spawnCallback({});
  } else {
    Config.prodLogger.e('template $template not found in lib :user');
  }
}
