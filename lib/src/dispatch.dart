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
// import 'package:dartrix/src/paths.dart';
// import 'package:dartrix/src/utils.dart';

// void dispatchPlugin(String pkg, String template, List<String> args) async {
//   // Config.debugLogger.v('dispatchPlugin: $pkg, $template, $args');

// FIXME: _options == Config.options
void processArgs(String pkg, String template, ArgResults _options,
    List<String> libArgs, List<String> tArgs) async {
  // Config.ppLogger.v('processArgs $pkg, $template, $_options, $libArgs, $tArgs');

  if (_options.wasParsed('help') ||
      libArgs.contains('-h') ||
      libArgs.contains('--help') ||
      tArgs.contains('-h') ||
      tArgs.contains('--help')) {
    print('\nLibrary \'$pkg\' options:');
    // printDartrixUsage();
  }

  // var pkgRoot = await resolvePkgRoot(pkg); // 'package:' + pkg + '_dartrix');
  // if (Config.verbose) {
  //   Config.ppLogger.v('resolved $pkg to package:${pkg}_dartrix to $pkgRoot');
  // }

  var templates = await getTemplatesMap(Config.libPkgRoot);
  // Config.debugLogger.v(templates);

  Config.templateRoot = Config.libPkgRoot + '/templates/' + template;
  // Config.debugLogger.v('Config.templateRoot: ${Config.templateRoot}');

  await setTemplateArgs(Config.templateRoot, libArgs, tArgs); // args);

  // if ( // _options.wasParsed('help') ||
  //     libArgs.contains('-h') || libArgs.contains('--help')) {
  //     print('Library: $pkg');
  //   // printDartrixUsage();
  // }

  // initPluginTemplates(pkg);

  Config.templateRoot = path.normalize(templates[template]['root']);
  // Config.prodLogger.v('saving Config.templateRoot = ${Config.templateRoot}');

  // await spawnPluginFromPackage(
  //     spawnCallback, externalOnDone, pkg, [template, ...?tArgs]);
}
