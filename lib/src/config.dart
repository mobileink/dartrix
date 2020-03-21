import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';

AnsiPen shoutPen = AnsiPen()..red(bold: true);
AnsiPen severePen = AnsiPen()..red(bold: true);
AnsiPen warningPen = AnsiPen()..green(bold: true);
AnsiPen infoPen = AnsiPen()..green(bold: false);
AnsiPen configPen = AnsiPen()..green(bold: true);

class Config {
  static bool verbose = false;
  static String appName;
  static String appSfx = '_dartrix';
  static String home;

  static ArgParser argParser;
  static ArgResults options;

  static void config(String _appName) {
    appName = _appName;
    //Map<String, String>
    var envVars = Platform.environment;
    if (Platform.isMacOS) {
      home = envVars['HOME'];
    } else if (Platform.isLinux) {
      home = envVars['HOME'];
    } else if (Platform.isWindows) {
      home = envVars['UserProfile'];
    }
  }
}
