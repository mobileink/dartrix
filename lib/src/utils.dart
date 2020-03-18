import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:logging/logging.dart';

var _log = Logger('utils');

AnsiPen shoutPen = new AnsiPen()..red(bold: true);
AnsiPen severePen = new AnsiPen()..red(bold: true);
AnsiPen warningPen = new AnsiPen()..red();
AnsiPen infoPen = new AnsiPen()..green(bold: false);
AnsiPen configPen = new AnsiPen()..green(bold: true);


bool verifyExists(String fsePath) {
  FileSystemEntityType fse = FileSystemEntity.typeSync(fsePath);
  return (fse != FileSystemEntityType.notFound);
}
