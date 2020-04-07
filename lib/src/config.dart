import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:logger/logger.dart';
import 'package:merge_map/merge_map.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

import 'package:dartrix/src/data.dart';
// import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/resolver.dart';
import 'package:dartrix/src/yaml.dart';

AnsiPen shoutPen = AnsiPen()..red(bold: true);
AnsiPen severePen = AnsiPen()..red(bold: true);
AnsiPen warningPen = AnsiPen()..green(bold: true);
AnsiPen infoPen = AnsiPen()..green(bold: false);
AnsiPen configPen = AnsiPen()..xterm(240);

// app config
class Config {
  static bool version = false;
  static bool verbose = false;
  static bool debug = false;
  static bool dryRun = false;
  static final logger = Logger(printer: SimplePrinter());
  static final debugLogger = Logger(printer: PrettyPrinter(methodCount: 6));

  static final prodLogger =
      Logger(filter: ProductionFilter(), printer: SimplePrinter());
  static final ppLogger = Logger(
      filter: ProductionFilter(), printer: PrettyPrinter(methodCount: 0));

  static String hereDir = '.dartrix.d/';
  static bool   here    = false;

  static bool   Y       = false; // --Y == fixpoint, identity xform

  static String userCache = home + '/.dart.d'; //FIXME: rename dartrixHome?
  static String dartrixDir = '.dartrix.d';
  static String dartrixHome = home + '/' + dartrixDir;

  static bool generic = false;
  static String genericIndex;
  static String genericSelection;
  // static String genericRewrite; // selection rewritten as output seg

  static String sysCache = getSysCache();

  static final String home = Platform.isWindows
      ? Platform.environment['UserProfile']
      : Platform.environment['HOME'];

  static final String local = '/usr/local/share/dartrix';

  static String appName;
  static String appSfx = '_' + appName;
  static String appPkgRoot;
  static String builtinTemplatesRoot;

  static String isoHome;

  static String libName;
  static String libPkgRoot;
  static String templateRoot;
  static String tLibDocString;

  static TemplateYaml templateYaml; // for memoization

  static ArgParser argParser;
  static ArgResults options;

  static bool searchLocal = false; // for list cmd
  static bool searchPubDev = false; // for list cmd

  // memoized metadata stuff from yaml params
  static String meta;
  static String metaName;
  static String outPathPrefix;

  static String replaceParam; // memoize for meta- and generic templates
  static String replaceText; // memoize for meta- and generic templates

  static bool force = false;

  static String _appVersion;

  static String get appVersion {
    if (_appVersion != null) return _appVersion;
    _appVersion = getAppVersion();
    return _appVersion;
  }

  static void config(String _appName) async {
    appName = _appName;
    await setAppPkgRoot(appName);
    await setBuiltinTemplatesRoot();
    // version = getAppPkgVersion();
    //Map<String, String>
    // var envVars = Platform.environment;
    // if (Platform.isMacOS) {
    //   home = envVars['HOME'];
    // } else if (Platform.isLinux) {
    //   home = envVars['HOME'];
    // } else if (Platform.isWindows) {
    //   home = envVars['UserProfile'];
    // }
  }
}

String getSysCache() {
  if (Platform.environment['PUB_CACHE'] != null) {
    return Platform.environment['PUB_CACHE'];
  } else {
    if (Platform.isWindows) {
      return '%APPDATA%\Pub\Cache';
    } else {
      return Platform.environment['HOME'] + '/.pub-cache';
    }
  }
}

//FIXME: implement
String getAppVersion() {
  var yaml = getAppYaml();
  return yaml['version'];
}

//FIXME: support constraints and ranges
Future<String> verifyAppVersion(String libPkgRoot) async {
  // Config.debugLogger.v('verifyAppVersion $libPkgRoot');
  var yaml = loadYamlFileSync(libPkgRoot + '/pubspec.yaml');
  if (yaml == null) {
    Config.prodLogger.w('verifyAppVersion: pubspec.yaml not found');
    return null;
  }
  // print('yaml: $yaml');
  var appVersionStr;
  try {
    appVersionStr = yaml['dartrix']['version'];
  } catch (e) {
    //FIXME: exit?
    Config.prodLogger.w(
        'Invalid plugin ${libPkgRoot} - missing required dartrix version in pubspec.yaml. Continuing anyway...');
    // exit(1);
    return null;
  }
  if (Config.version) {
    Config.prodLogger.v('Plugin ${path.basename(libPkgRoot)} built for dartrix version: $appVersionStr');
  }

  var appVersion = Version.parse(appVersionStr);
  // print('parse version: $appVersion');
  // print('min: ${appVersion.min}');
  // print('min: ${appVersion.max}');

  // print('dartrix version: ${await Config.appVersion}');
  if (appVersion <= Version.parse(await Config.appVersion)) {
    return null;
  } else {
    return appVersionStr;
  }
}

// dynamic mergeMapx(Map val) {
//   val.forEach((k,v) {
//       if (v is Map) {
//         var m = mergeMap(v);
//         return {k : m};
//       } else {
//         return {k: v};
//       }
//   });
// }

void loadConfigFile(String configFile) async {
  var f = path.canonicalize(Directory.current.path + '/' + configFile);
  var yaml = loadYamlFileSync(f);
  tData = mergeMap([tData, yaml['data']]);
}
