import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:logger/logger.dart';
import 'package:safe_config/safe_config.dart';

import 'package:dartrix/src/resolver.dart';

AnsiPen shoutPen = AnsiPen()..red(bold: true);
AnsiPen severePen = AnsiPen()..red(bold: true);
AnsiPen warningPen = AnsiPen()..green(bold: true);
AnsiPen infoPen = AnsiPen()..green(bold: false);
AnsiPen configPen = AnsiPen()..green(bold: true);

String getPubCache() {
  if  (Platform.environment['PUB_CACHE'] != null) {
    return Platform.environment['PUB_CACHE'];
  } else {
    if (Platform.isWindows) {
      return '%APPDATA%\Pub\Cache';
    } else {
      return Platform.environment['HOME'] + '/.pub-cache';
    }
  }
}

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

  static String pubCache = getPubCache();

  static final String home = Platform.isWindows
      ? Platform.environment['UserProfile']
      : Platform.environment['HOME'];

  static String appName;
  static String appSfx = '_dartrix';
  static String appPkgRoot;

  static String libPkgRoot;
  static String templateRoot;

  static ArgParser argParser;
  static ArgResults options;

  static String _version;

  static Future<String> get pkgVersion async {
    if (_version != null) return _version;
    _version = await getPkgVersion();
    return _version;
  }

  static void config(String _appName) async {
    appName = _appName;
    await getAppPkgRoot(appName);
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

TemplateConfig getTemplateConfig(String template) {
  var config;
  try {
    config = TemplateConfig(template + '.yaml');
  } catch (e) {
    if (Config.debug) {
      Config.debugLogger.e(e);
    } else {
      Config.logger.e(e);
    }
  }
  return config;
}
