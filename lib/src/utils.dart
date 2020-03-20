import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/utils.dart';

var _log = Logger('utils');

AnsiPen shoutPen = new AnsiPen()..red(bold: true);
AnsiPen severePen = new AnsiPen()..red(bold: true);
AnsiPen warningPen = new AnsiPen()..red();
AnsiPen infoPen = new AnsiPen()..green(bold: false);
AnsiPen configPen = new AnsiPen()..green(bold: true);

String getDocstring(Package pkg) {
  var rootDir = pkg.root.path;
  var libName  = pkg.name.replaceFirst(RegExp('_dartrix'),'');
  var docstringName = libName+ ".docstring";
  String docstring = File(rootDir + "/" + docstringName).readAsStringSync();
  //TODO: break long lines
  return docstring;
}

/// Verify that cwd is root of a Dartrix package.
void sanityCheck() {
  if (debug.verbose) _log.info("Sanity check...");
  String cwd = Directory.current.path;
  if ( !path.basename(cwd).endsWith("_dartrix")) {
    _log.warning("Not in a dartrix package directory. Package name (cwd) must end in '_dartrix'.");
    exit(0);
  }
  if (debug.verbose) _log.info("... cwd ends with '_dartrix' - ok");

  var exists = FileSystemEntity.typeSync(cwd + "/lib/dartrix.dart");
  if (exists == FileSystemEntityType.notFound) {
    _log.severe("lib/dartrix.dart not found");
    exit(0);
  }
  if (debug.verbose) _log.info("... ./lib/dartrix.dart exists - ok");

  exists = FileSystemEntity.typeSync(cwd + "/lib/templates");
  if (exists == FileSystemEntityType.notFound) {
    _log.severe("./lib/templates directory not found");
    exit(0);
  }
  if (debug.verbose) _log.info("... ./lib/templates directory exists - ok");

  exists = FileSystemEntity.typeSync(cwd + "/lib/man");
  if (exists == FileSystemEntityType.notFound) {
    _log.severe("./lib/man directory not found");
    exit(0);
  }
  if (debug.verbose) _log.info("... ./lib/man directory exists - ok");

  if (debug.verbose) _log.info("Sanity check passed.");
}

