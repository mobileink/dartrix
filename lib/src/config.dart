import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:logger/logger.dart';
import 'package:merge_map/merge_map.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:safe_config/safe_config.dart';
import 'package:yaml/yaml.dart';

import 'package:dartrix/src/data.dart';
// import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/resolver.dart';

AnsiPen shoutPen = AnsiPen()..red(bold: true);
AnsiPen severePen = AnsiPen()..red(bold: true);
AnsiPen warningPen = AnsiPen()..green(bold: true);
AnsiPen infoPen = AnsiPen()..green(bold: false);
AnsiPen configPen = AnsiPen()..green(bold: true);

// app config
class Config {
  static bool verbose = false;
  static bool debug = false;
  static bool dryRun = false;
  static final logger = Logger(printer: SimplePrinter());
  static final debugLogger = Logger(printer: PrettyPrinter(methodCount: 6));

  static final prodLogger =
      Logger(filter: ProductionFilter(), printer: SimplePrinter());
  static final ppLogger = Logger(
      filter: ProductionFilter(), printer: PrettyPrinter(methodCount: 0));

  //FIXME: rename dartrixHome?
  static String userCache = home + '/.dart.d';

  static String sysCache = getSysCache();

  static final String home = Platform.isWindows
      ? Platform.environment['UserProfile']
      : Platform.environment['HOME'];

  static String appName;
  static String appSfx = '_' + appName;
  static String appPkgRoot;
  static String builtinTemplatesRoot;

  static String isoHome;

  static String libName;
  static String libPkgRoot;
  static String templateRoot;

  static ArgParser argParser;
  static ArgResults options;

  static bool searchPubDev = false; // for list cmd

  static String _appVersion;

  static Future<String> get appVersion async {
    if (_appVersion != null) return _appVersion;
    _appVersion = await getAppVersion();
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

// safe_config yaml classes
class ParamConfig extends Configuration {
  ParamConfig() : super();
  ParamConfig.fromFile(String fileName) : super.fromFile(File(fileName));
  ParamConfig.fromMap(Map m) : super.fromMap(m);

  String name;
  @optionalConfiguration
  String abbr;
  String docstring;
  @optionalConfiguration
  String help;
  String typeHelp; // parser 'valueHelp'
  String defaultsTo;
  @optionalConfiguration
  String seg;
  @optionalConfiguration
  String hook;
}

class TemplateConfig extends Configuration {
  TemplateConfig(String fileName) : super.fromFile(File(fileName));

  String name;
  String description;
  String docstring;
  String version;
  List<ParamConfig> params;
  @optionalConfiguration
  String note;
}

// String loadTemplateFileSync(String path) {
//   File file = new File(path);
//   if (file?.existsSync() == true) {
//     return file.readAsStringSync();
//   }
//   return null;
// }

// Future<String> loadTemplateFile(String path) async{
//   File file = new File(path);
//   if ((await file?.exists()) == true) {
//     String content = await file.readAsString();
//     return content;
//   }
//   return null;
// }

TemplateConfig getTemplateConfig(String templateRoot) {
  var config;
  try {
    config = TemplateConfig(templateRoot + '/dartrix.yaml');
  } catch (e) {
    if (Config.debug) {
      Config.debugLogger.e(e);
    } else {
      Config.logger.e(e);
    }
  }
  return config;
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
Future<String> getAppVersion() async {
  var yaml = getAppYaml();
  return yaml['version'];
}

Map loadYamlFileSync(String path) {
  //File
  var file = File(path);
  if (file?.existsSync() == true) {
    return loadYaml(file.readAsStringSync());
  }
  return null;
}

Future<Map> loadYamlFile(String path) async {
  //File
  var file = File(path);
  if ((await file?.exists()) == true) {
    return loadYaml(await file.readAsString());
  }
  return null;
}

Map getAppYaml() {
  var yaml = loadYamlFileSync(Config.appPkgRoot + '/pubspec.yaml');
  return yaml;
}

//FIXME: support constraints and ranges
Future<String> verifyAppVersion(String libPkgRoot) async {
  // Config.ppLogger.v('verifyDartrixVersion $libPkgRoot');
  var yaml = loadYamlFileSync(libPkgRoot + '/pubspec.yaml');
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
  if (Config.verbose) {
    Config.prodLogger.v('Required dartrix version: $appVersionStr');
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
  var f = path.normalize(Directory.current.path + '/' + configFile);
  var yaml = loadYamlFileSync(f);
  tData = mergeMap([tData, yaml['data']]);
}
