import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/config.dart';
// import 'package:dartrix/src/debug.dart' as debug;
// import 'package:dartrix/src/utils.dart';

var _log = Logger('utils');

AnsiPen shoutPen = AnsiPen()..red(bold: true);
AnsiPen severePen = AnsiPen()..red(bold: true);
AnsiPen warningPen = AnsiPen()..red();
AnsiPen infoPen = AnsiPen()..green(bold: false);
AnsiPen configPen = AnsiPen()..green(bold: true);

String getDocstring(Package pkg) {
  var rootDir = pkg.root.path;
  var libName = pkg.name.replaceFirst(RegExp('_dartrix'), '');
  var docstringName = libName + '.docstring';
  var docstring = File(rootDir + '/' + docstringName).readAsStringSync();
  //TODO: break long lines
  return docstring;
}

/// Verify that cwd is root of a Dartrix package.
void sanityCheck() {
  if (Config.verbose) _log.info('Sanity check...');
  var cwd = Directory.current.path;
  var cwdName = path.basename(Directory.current.path);
  if (!cwdName.endsWith(Config.appSfx)) {
    _log.warning(
        'Not in a dartrix package directory. Package name (cwd) must end in "_dartrix".');
    exit(0);
  }
  if (Config.verbose) _log.info('... cwd ends with "_dartrix" - ok');

  var mainDart = 'lib/' + cwdName + '.dart';
  var exists = FileSystemEntity.typeSync(mainDart);
  if (exists == FileSystemEntityType.notFound) {
    _log.severe('${mainDart} not found');
    exit(0);
  }
  if (Config.verbose) _log.info('... .${mainDart} exists - ok');

  exists = FileSystemEntity.typeSync(cwd + '/templates');
  if (exists == FileSystemEntityType.notFound) {
    _log.severe('./templates directory not found');
    exit(0);
  }
  if (Config.verbose) _log.info('... ./templates directory exists - ok');

  exists = FileSystemEntity.typeSync(cwd + '/man');
  if (exists == FileSystemEntityType.notFound) {
    _log.severe('./man directory not found');
    exit(0);
  }
  if (Config.verbose) _log.info('... ./man directory exists - ok');

  if (Config.verbose) _log.info('Sanity check passed.');
}
