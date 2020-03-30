import 'dart:core';
import 'dart:io';
// import 'dart:isolate';

import 'package:args/args.dart';
// import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
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

void printPlugins(String libName, ArgResults options) async {
  // Config.ppLogger.v('printPlugins $libName, $options');
  // var libName = options.rest[0];

  //List<Map>
  var pkgList = await resolvePkg(libName);
  Config.ppLogger.d('pkgList: $pkgList');

  // pkgList may contain many versions.  find the most recent.
  // i.e. sort by version in descending order
  pkgList.sort((a,b) {
      int order = a['name'].compareTo(b['name']);
      if (order != 0) {
        return order;
      } else {
        return (Version.parse(a['version']) > Version.parse(b['version']))
        ? -1 : 1;
    }
  });
  Config.ppLogger.d('sorted: $pkgList');
  //String
  Config.libPkgRoot = pkgList[0]['rootUri']; // Highest version
  // if (Config.debug) {
  //   Config.logger.d(
  //       'resolved $libName to package:${libName}_dartrix to ${Config.libPkgRoot}');
  // }
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
      if (Config.debug) {
        docString = warningPen('${tName}.docstring not found');
      }
    }
    var version = getPluginVersion(Config.libPkgRoot);
    // Config.ppLogger.d('version: $version');
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
    // print('\nAvailable template libraries:\n');
    print('');
    // print header
    var header = sprintf(format, ['  Library', 'Version', 'Description']);
    print('${infoPen(header)}');

    var builtins = sprintf(
        format, ['  dartrix', await Config.appVersion, 'builtin templates']);
    print('$builtins');
  }

  var libName;
  var plugin;
  var star = ' ';
  pkgs.forEach((pkg) {
    libName = pkg['name'].replaceFirst(RegExp('_dartrix\$'), '');
    switch (pkg['src']) {
      case 'path':
        star = '  ';
        break;
      case 'syscache':
        star = ' *';
        break;
      case 'pubdev':
        star = '**';
        break;
      default:
        star = '??';
    }
    var docString = pkg['docstring'] ??
        getDocStringFromPkg(libName, pkg['rootUri'] ?? pkg['path']);
    // var penName = infoPen(libName);
    // print('libname ${libName} len: ${penName.length}');
    if (pkg['path'] == null) {
      libName = '${star}${libName}';
    } else {
      libName = '${star}${libName}';
      // libName = sprintf('%-27s', ['${star}${infoPen(libName)}']);
    }
    plugin = sprintf(format, [libName, pkg['version'], docString]);
    // var star = (pkg['syscache'] == 'true') ? '*' : ' ';
    if (!Config.debug) {
      print('$plugin');
      if (pkg['path'] != null) {
        print(sprintf(format, ['', '', '${infoPen("path")}: ${pkg["path"]}']));
      }
    }
  });
  if (!Config.debug) {
    // print('\n${infoPen("path")}: active library');
    print('\n*  Installed in local syscache (~/.pub-cache)');
    if (Config.searchPubDev) {
      print('** Available on pub.dev\n');
    } else {
      print('');
    }
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

  // var pkg = await resolvePkg(libName);

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
