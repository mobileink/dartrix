import 'dart:core';
import 'dart:io';
// import 'dart:isolate';

import 'package:args/args.dart';
// import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:sprintf/sprintf.dart';

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/builtins.dart';
import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/resolver.dart';
// import 'package:dartrix/src/utils.dart';

// void initBuiltinArgs(Dartrix cmd) async { //CommandRunner runner) async {
void initBuiltinArgs() async {
  //CommandRunner runner) async {
  // {template : docstring }
  // Map
  var biTemplates = await getTemplatesMap(null); // listBuiltinTemplates();
  // for each template, read yaml and construct arg parser

  // for (var t in biTemplates.keys) {
  //   var tConfig = getTemplateConfig(t);
  //   // print('$t config: ${tConfig.name}');
  //   var subCmd = Dartrix.cmd(tConfig.name, tConfig.docstring);
  //   tConfig.params.forEach((p) {
  //       // var subCmd = Dartrix.cmd(p['name'], p['desc']);
  //       subCmd.addOption(p.name, abbr: p.abbr,
  //         help: p.help,
  //         valueHelp: p.typeHelp,
  //         defaultsTo: p.defaultsTo);
  //   });
  //   // cmd.addSubcommand(subCmd);
  //   // runner.addCommand(cmd);
  // }
  var opts = biTemplates.keys.map((k) => path.basename(k));
  print('bit keys: $opts');
  // cmd.addOption('template', abbr: 't',
  //   allowed: opts);
}

// void printBuiltins() async { // ArgResults options)
//   // print('printBuiltins ${options.arguments}');
//   //Uri
//   // var packageConfigUri = await Isolate.packageConfig;
//   // // e.g. file:///Users/gar/mobileink/dartrix/.packages
//   // if (Config.debug) {
//   //   Config.logger.i('packageConfigUri $packageConfigUri');
//   // }

//   // WARNING: for pub global activateds, the current dir of the script contains
//   // .packages, which is the value of Isolate.packageConfig, but it does NOT
//   // contain all of the subdirs of the original pkg root. It only the bin dir,
//   // plus the pub stuff (.dart_tool, .packages, pubspec.lock).

//   // e.g.
//   // $ l ~/.pub-cache/global_packages/stagehand/
//   // total 8.0K
//   // drwxr-xr-x 3 gar staff  102 Mar 10 18:40 .dart_tool/
//   // -rw-r--r-- 1 gar staff 2.9K Mar 10 18:40 .dart_tool/package_config.json
//   // -rw-r--r-- 1 gar staff 1.3K Mar 10 18:40 .packages
//   // drwxr-xr-x 3 gar staff  102 Mar 10 18:40 bin/
//   // -rw-r--r-- 1 gar staff 1.3M Mar 10 18:40 bin/stagehand.dart.snapshot.dart2
//   // -rw-r--r-- 1 gar staff 2.4K Mar 10 18:40 pubspec.lock

//   // So to find the templates/ dir, we have to look it up in the .packages file
//   // using findPackageConfigUri.  this is a v1 pkg config, i.e. a .packages
//   // file, so back up one segment: String libDir =
//   // path.dirname(packageConfigUri.path); var templatesRoot =
//   // path.dirname(packageConfigUri.path) + '/templates'; List

//   var templatesRoot = await resolveBuiltinTemplatesRoot();
//   var templates = Directory(templatesRoot)
//   .listSync()
//   ..retainWhere((f) => f is Directory);

//   print('Dartrix Template Library:');
//   templates.forEach((t) {
//     var tName = path.basename(t.path);
//     //String
//     var docString;
//     try {
//       docString =
//           File(templatesRoot + '/' + tName + '.docstring').readAsStringSync();
//     } on FileSystemException {
//       // if (debug.debug)
//       // Config.logger.i('docstring not found for ${builtin.path}');
//       if (debug.debug) {
//         docString = warningPen('${tName}.docstring not found');
//         // tName = warningPen(sprintf('%-18s', [tName]));
//       }
//     }
//     tName = sprintf('%-18s', [tName]);
//     print('\t${tName} ${docString}');
//   });
// }

void printPlugins(String libName, ArgResults options) async {
  // Config.ppLogger.v('printPlugins $libName, $options');
  // var libName = options.rest[0];
  var pkg = await resolvePkg(libName);
  // Config.ppLogger.d('pkg: $pkg');
  //String
  Config.libPkgRoot = pkg['rootUri'];
  if (Config.debug) {
    Config.logger.d(
        'resolved $libName to package:${libName}_dartrix to ${Config.libPkgRoot}');
  }
  //String
  var templatesRoot = Config.libPkgRoot + '/templates';
  // if (Config.verbose) {
  //   Config.logger.i('templatesRoot: $templatesRoot');
  // }
  //List
  var templates = Directory(templatesRoot).listSync();
  templates.retainWhere((f) => f is Directory);
  print('package:${libName}_dartrix templates:');
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

String abbrevPath(String path) {
  return path.startsWith(Config.home)
      ? '~' + path.replaceFirst(Config.home, '')
      : path;
}

void printUsage(ArgParser argParser) async {
  if (!Config.debug) {
    print('dartrix:list, version 0.1.0\n');
    print('Usage: dartrix:list [-h] <library>\n');
    // print('Options (for builtins and plugin libraries only):\n');
    print(argParser.usage);
  }
  // pkgs: map of pkgname: uri
  //List<Map>
  var pkgs = await getPlugins(Config.appSfx);
  // Config.ppLogger.v('pkgs: $pkgs');

  final format = '  %-14s%-14s%-70s';
  if (!Config.debug) {
    print('\nAvailable template libraries:\n');

    // print header
    var header = sprintf(format, [' Library', 'Version', 'Description']);
    print('${infoPen(header)}');

    var builtins = sprintf(
        format, [' dartrix', await Config.appVersion, 'builtin templates']);
    print('$builtins');
  }

  var libName;
  var plugin;
  var star = ' ';
  pkgs.forEach((pkg) {
    libName = pkg['name'].replaceFirst(RegExp('_dartrix\$'), '');
    if ((pkg['rootUri'] == null) && (pkg['path'] == null)) {
      star = '*';
    } else {
      star = ' ';
    }
    var docString = pkg['docstring'] ??
        getDocStringFromPkg(libName, pkg['rootUri'] ?? pkg['path']);
    plugin = sprintf(format, [
      star + libName,
      pkg['version'],
      docString
      // (pkg['rootUri'] == null)
      // ? ((pkg['path'] == null)
      //   ? 'pub.dev'
      //   : abbrevPath(pkg['path']))
      // : 'syscache'
    ]);
    // var star = (pkg['syscache'] == 'true') ? '*' : ' ';
    if (!Config.debug) {
      print('$plugin');
      if (pkg['path'] != null) {
        print(sprintf(format, ['', '', '${infoPen("path")}: ${pkg["path"]}']));
      }
    }
  });
  if (!Config.debug) {
    print('\n* Available on pub.dev\n');
  }
}

void main(List<String> args) async {
  if (args.contains('--debug')) {
    Config.debug = true;
    debug.debug = true;
  }
  await Config.config('dartrix');

  var argParser = ArgParser(usageLineLength: 120);
  // argParser.addCommand('list');
  argParser.addFlag('pubdev',
      abbr: 'p', defaultsTo: false, help: 'Search pub.dev. Default: false');
  argParser.addFlag('help',
      abbr: 'h', defaultsTo: false, help: 'Print this help message.');
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('debug', defaultsTo: false, hide: true);

  try {
    Config.options = argParser.parse(args);
  } catch (e) {
    Config.logger.e(e);
    exit(0);
  }

  // if (Config.options['debug']) {
  //   Config.debug = true;
  //   debug.debug = true;
  // }

  Config.verbose = Config.options['verbose'];
  if (debug.debug) {
    debug.debugOptions();
    Config.debug = true;
  }

  // // var root = path.dirname(Platform.script.toString());
  // // print('proj root: $root');

  if (Config.options['help']) {
    await printUsage(argParser);
    if (Config.debug) {
      Config.debug = false;
      await printUsage(argParser);
    }
    exit(0);
  }

  Config.searchPubDev = Config.options['pubdev'];
  // print('searchPubDev: ${Config.searchPubDev}');

  if (Config.debug) {
    await debug.debugConfig();
  }

  if (Config.options.rest.isEmpty) {
    // if Config.debug is set, printUsage will only print debug msgs
    await printUsage(argParser);
    // Now reset Config.debug and print usage
    if (Config.debug) {
      Config.debug = false;
      await printUsage(argParser);
    }
    // var bis = await listBuiltinTemplates();
    // print('bis: $bis');
  } else {
    switch (Config.options.rest[0]) {
      case 'dartrix':
        await printBuiltins(); // Config.options);
        break;
      case 'help':
      case '-h':
      case '--help':
        await printUsage(argParser);
        exit(0);
        break;
      default:
        printPlugins(Config.options.rest[0], Config.options);
    }
  }
}
