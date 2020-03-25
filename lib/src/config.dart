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

// app config
class Config {
  static bool verbose = false;
  static bool debug = false;
  static final logger = Logger(printer: SimplePrinter());
  static final debugLogger = Logger(printer: PrettyPrinter(methodCount:4));
  static final prodLogger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(methodCount: 0)
  );
  static String appName;
  static String appSfx = '_dartrix';
  static String appPkgRoot;
  static final String home
  = Platform.isWindows
  ? Platform.environment['UserProfile']
  : Platform.environment['HOME'];

  static ArgParser argParser;
  static ArgResults options;

  static String _version = null;

  static Future<String> get pkgVersion async {
    if (_version != null) return _version;
    _version = await getPkgVersion();
    return _version;
  }

  static void config(String _appName) {
    appName = _appName;
    getAppPkgRoot();
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
	String abbr;
	String docstring;
  String help;
  String typeHelp;            // parser 'valueHelp'
	String defaultsTo;
  @optionalConfiguration
  String segmap;
}

class TemplateConfig extends Configuration {
 	TemplateConfig(String fileName) : super.fromFile(File(fileName));

    String name;
	  String description;
    String docstring;
    String version;
	  List<ParamConfig> params;
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
  } catch(e) {
    if (Config.debug) {
      Config.debugLogger.e(e);
    } else {
      Config.logger.e(e);
    }
  }
  return config;
}
