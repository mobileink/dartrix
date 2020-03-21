import 'dart:io';
import 'package:args/args.dart';

class Config {
  static bool verbose = false;
  static String appName;
  static String appSfx = "_dartrix";
  static String home;

  static ArgParser argParser;
  static ArgResults options;

  static void config(String _appName) {
    appName = _appName;
    Map<String, String> envVars = Platform.environment;
    if (Platform.isMacOS) {
      home = envVars['HOME'];
    } else if (Platform.isLinux) {
      home = envVars['HOME'];
    } else if (Platform.isWindows) {
      home = envVars['UserProfile'];
    }
  }
}
