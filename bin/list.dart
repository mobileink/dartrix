import 'dart:core';
import 'dart:io';
// import 'dart:isolate';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
// import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:sprintf/sprintf.dart';

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/builtins.dart';
import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/lister.dart';
import 'package:dartrix/src/resolver.dart';
import 'package:dartrix/src/utils.dart';
import 'package:dartrix/src/yaml.dart';

// void initBuiltinArgs(Dartrix cmd) async { //CommandRunner runner) async {
void initBuiltinArgs() async {
  //CommandRunner runner) async {
  // {template : docstring }
  // Map
  var biTemplates = await listTemplatesAsMap(null); // listBuiltinTemplates();
  // for each template, read yaml and construct arg parser

  // for (var t in biTemplates.keys) {
  //   var tConfig = getTemplateYaml(t);
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

void printLocalTemplates() async {
  // Config.ppLogger.v('printLocalTemplates entry'); //, ${options');
  List<Map> localTemplates = listLocalTemplates();
  print(':local templates (${Config.local}/templates):');
  String tName;
  localTemplates.forEach((t) {
    tName = sprintf('%-18s', [t['name']]);
    print('\t${tName} ${t["docstring"]}');
  });
}

void printUserTemplates() async {
  // Config.ppLogger.v('printUserTemplates entry'); //, ${options');
  List<Map> userTemplates = listUserTemplates();
  if (userTemplates.isNotEmpty) {
    print(
        ':user templates (~/.dartrix.d/templates):'); //FIME: add  (${userDartrixHome})
  }
  String tName;
  userTemplates.forEach((t) {
    tName = sprintf('%-18s', [t['name']]);
    print('\t${tName} ${t["docstring"]}');
  });
}

void printBuiltins() async {
  // var templatesRoot = await resolveBuiltinTemplatesRoot();
  // var templates = Directory(templatesRoot).listSync()
  //   ..retainWhere((f) => f is Directory);

  print('Builtin templates:');

  // var templates = await listTemplatesAsMap(null);
  var templates = await listBuiltinTemplates();
  var tName;
  templates.forEach((t) {
      tName = sprintf('%-18s', [t['name']]);
      print('\t${tName} ${t["docstring"]}');
  });
}

void printPluginTemplates(String libName, ArgResults options) async {
  // Config.ppLogger.v('printPluginTemplates $libName'); //, ${options');

  // canonicalize libName
  // switch (libName) {
  //   case ':.': libName = ':here'; break;
  //   case ':u': libName = ':home'; break;
  //   case ':user': libName = ':home'; break;
  //   default: // nop
  // }

  //List<Map>
  var userLibs = await resolvePkg(libName);
  // Config.ppLogger.d('userLibs: $userLibs');

  if (userLibs.isEmpty) return;

  // userLibs may contain many versions.  find the most recent.
  // i.e. sort by version in descending order
  userLibs.sort((a, b) {
    int order = a['name'].compareTo(b['name']);
    if (order != 0) {
      return order;
    } else {
      return (Version.parse(a['version']) > Version.parse(b['version']))
          ? -1
          : 1;
    }
  });
  // Config.ppLogger.d('sorted: $userLibs');
  //String
  Config.libPkgRoot = userLibs[0]['rootUri']; // Highest version
  // if (Config.debug) {
  //   Config.logger.d(
  //       'resolved $libName to package:${libName}_dartrix to ${Config.libPkgRoot}');
  // }
  //String
  var templatesRoot =
      // Config.libPkgRoot + '/' + ((libName == ':here') ?  : '') + 'templates';
      Config.libPkgRoot + '/templates';
  // if (Config.verbose) {
  //   Config.logger.i('templatesRoot: $templatesRoot');
  // }
  //List
  var templates = Directory(templatesRoot).listSync();
  templates.retainWhere((f) => f is Directory);
  // print(libName);
  switch (libName) {
    case ':here':
      print(':here templates (${Config.hereDir}):');
      break;
    case ':h':
    case ':home':
      print(':home templates:');
      break;
    case ':l':
    case ':local':
      print(':local templates:');
      break;
    default:
      print('package:${libName}_dartrix templates:');
  }
  templates.forEach((t) {
    TemplateYaml tConfig = getTemplateYaml(t.path);
    var tName = path.basename(t.path);
    var docString = tConfig.docstring;
    // try {
    //   docString =
    //       File(templatesRoot + '/' + tName + '.docstring').readAsStringSync();
    // } on FileSystemException {
    //   if (Config.debug) {
    //     docString = warningPen('${tName}.docstring not found');
    //   }
    // }
    // var version = getPluginVersion(Config.libPkgRoot);
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
  // Config.ppLogger.d('printUsage entry');
  if (!Config.debug) {
    print('dartrix:list, version 0.1.0\n');
    print('Usage: dartrix:list [plhv] [<library>]\n');
    // print('Options (for builtins and plugin libraries only):\n');
    print(argParser.usage);
  }
  final format = '  %-14s%-14s%-70s';
  if (!Config.debug) {
    // print('\nAvailable template libraries:\n');
    print('');
    // print header
    var header = sprintf(format, ['Library', 'Version', 'Description']);
    print('${infoPen(header)}');

    var line = sprintf(
        format, [':dartrix', await Config.appVersion, 'builtin templates']);
    print('$line');

    String v;
    AnsiPen stdPen = AnsiPen();
    AnsiPen thePen = stdPen;
    if (stdTLibExists(':here')) {
      v = '';
    } else {
      v = '[not used]';
      thePen = configPen;
      if (Config.verbose) {
        Config.prodLogger.i(infoPen(':here template library not found (./.templates)'));
      }
    }
    line = sprintf(
      format, [':here', '$v', 'Here templates (./.templates)']);
    print(thePen('$line'));

    if (stdTLibExists(':user')) {
      v = '';
      thePen = stdPen;
    } else {
      thePen = configPen;
      v = '[not used]';
      if (Config.verbose) {
        Config.prodLogger.i(infoPen(':user template library not found (${Config.dartrixHome}/templates)'));
      }
    }
    line = sprintf(format,
      [':user', '$v', 'User (private) templates (~/.dartrix.d/templates)']);
    print(thePen('$line'));

    if (Config.searchLocal) {
      if (stdTLibExists(':local')) {
        v = '';
        thePen = stdPen;
      } else {
        thePen = configPen;
        v = '[not used]';
        if (Config.verbose) {
          Config.prodLogger.i(infoPen(':local template library not found (${Config.local}/templates)'));
        }
      }
      var l = sprintf(format,
        [':local', v, ':local templates (${Config.local}/templates)']);
      print(thePen('$l'));
    }
  }
  print('\nImports:');
  // pkgs: map of pkgname: uri
  //List<Map>
  var plugins = await listTLibs(Config.appSfx);
  // Config.ppLogger.v('plugins: $plugins');

  var libName;
  var plugin;
  var star = ' ';
  plugins.forEach((plugin) {
      // print('PLUGIN: $plugin');
    libName = plugin['name'].replaceFirst(RegExp('_dartrix\$'), '');
    switch (plugin['scope']) {
      //FIXME
      case 'user':
        star = '*';
        break;
      case 'local':
        star = '+';
        break;
      case 'sys':
        star = '>';
        break;
      case 'pubdev':
        star = '^';
        break;
      default:
        star = '?';
    }
    // var docString = plugin['docstring'] ??
    //     getDocStringFromPkg(libName, plugin['rootUri'] ?? plugin['path']);
    // var penName = infoPen(libName);
    // print('libname ${libName} len: ${penName.length}');
    // if (plugin['path'] == null) {
    //   libName = '${star}${libName}';
    // } else {
      libName = '${star}${libName}';
      // libName = sprintf('%-27s', ['${star}${infoPen(libName)}']);
    // }
    var pluginStr =
        sprintf(format, [libName, plugin['version'], plugin['docstring']]);
    // var star = (plugin['syscache'] == 'true') ? '*' : ' ';
    if (!Config.debug) {
      print('$pluginStr');
      if ((plugin['scope'] == 'user') || (plugin['scope'] == 'local')) {
        print(sprintf(
            format, ['', '', '${infoPen("path")}: ${plugin["rootUri"]}']));
      }
    }
  });
  if (!Config.debug) {
    // print('\n${infoPen("path")}: active library');
    // print('\n* User (~/.dartrix.d/user.yaml)   + Local (${Config.local})');
    // print('> System (~/.pub-cache)');
    print('\n*User  '
      + ((Config.searchLocal) ? '+Local' : '')
      + '  >System'
      + ((Config.searchPubDev) ? '  ^pub.dev' : ''));
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
      abbr: 'p', defaultsTo: false, help: 'List pub.dev. Default: no');
  argParser.addFlag('local',
      abbr: 'l', defaultsTo: false, help: 'List local (/usr/local/share/dartrix) Default: no');
  argParser.addFlag('help',
      abbr: 'h', defaultsTo: false, help: 'Print this help message.');
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('debug', defaultsTo: false, hide: true);

  try {
    Config.options = argParser.parse(args);
  } catch (e) {
    Config.logger.e('$e');
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

  Config.searchPubDev = Config.options['pubdev'];
  Config.searchLocal = Config.options['local'];
  // print('searchPubDev: ${Config.searchPubDev}');

  if (Config.options['help']) {
    await printUsage(argParser);
    if (Config.debug) {
      Config.debug = false;
      await printUsage(argParser);
    }
    exit(0);
  }

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
    Config.libName = canonicalizeLibName(Config.options.rest[0]);
    //{Config.libName);
    switch (Config.libName) { // Config.options.rest[0]) {
      case ':d':
      case ':dartrix':
        await printBuiltins(); // Config.options);
        break;
      case ':h':
      case ':home':
        await printUserTemplates(); // Config.options);
        break;
      case ':l':
      case ':local':
        await printLocalTemplates(); // Config.options);
        break;
      case 'help':
      case '-h':
      case '--help':
        await printUsage(argParser);
        exit(0);
        break;
      default:
      if (Config.libName.startsWith(':')) {
        print('No template library with key \'${Config.libName}\'. Available keys: :. (:here), :u (:user), :l (:local), :d (:dartrix)');
      } else {
        // printPluginTemplates(Config.options.rest[0], Config.options);
        printPluginTemplates(Config.libName, Config.options);
      }
    }
  }
}
