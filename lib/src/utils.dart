import 'dart:io';

// import 'package:args/args.dart';
// import 'package:ansicolor/ansicolor.dart';
// import 'package:logger/logger.dart';
// import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/config.dart';
// import 'package:dartrix/src/data.dart';
// import 'package:dartrix/src/debug.dart' as debug;
// import 'package:dartrix/src/utils.dart';

//var Config.logger = Logger('utils');

/// Verify that cwd is root of a Dartrix package.
void sanityCheck() {
  if (Config.verbose) Config.logger.i('Sanity check...');
  var cwd = Directory.current.path;
  var cwdName = path.basename(Directory.current.path);
  if (!cwdName.endsWith(Config.appSfx)) {
    Config.logger.w(
        'Not in a dartrix package directory. Package name (cwd) must end in "_dartrix".');
    exit(0);
  }
  if (Config.verbose) Config.logger.i('... cwd ends with "_dartrix" - ok');

  var mainDart = 'lib/' + cwdName + '.dart';
  var exists = FileSystemEntity.typeSync(mainDart);
  if (exists == FileSystemEntityType.notFound) {
    Config.logger.e('${mainDart} not found');
    exit(0);
  }
  if (Config.verbose) Config.logger.i('... .${mainDart} exists - ok');

  exists = FileSystemEntity.typeSync(cwd + '/templates');
  if (exists == FileSystemEntityType.notFound) {
    Config.logger.e('./templates directory not found');
    exit(0);
  }
  if (Config.verbose) Config.logger.i('... ./templates directory exists - ok');

  exists = FileSystemEntity.typeSync(cwd + '/man');
  if (exists == FileSystemEntityType.notFound) {
    Config.logger.e('./man directory not found');
    exit(0);
  }
  if (Config.verbose) Config.logger.i('... ./man directory exists - ok');

  if (Config.verbose) Config.logger.i('Sanity check passed.');
}

String normalizeLibName(String libName) {
  switch (libName) {
    case ':.': return ':here'; break;
    case ':h': return ':home'; break;
    case ':u': return ':home'; break;
    case ':user': return ':home'; break;
    case ':l': return ':local'; break;
    default: return libName;
  }
}

bool verifyExists(String fsePath) {
  var fse = FileSystemEntity.typeSync(fsePath);
  return (fse != FileSystemEntityType.notFound);
}

bool stdTLibExists(String scope) {
  var path;
  var fse;
  switch (scope) {
    case ':here':
    path = './.templates';
    fse = FileSystemEntity.typeSync(path);
    return (fse != FileSystemEntityType.notFound);
    break;
    case ':user':
    path = Config.dartrixHome + '/templates';
    fse = FileSystemEntity.typeSync(path);
    return (fse != FileSystemEntityType.notFound);
    break;
    case ':local':
    path = Config.local + '/templates';
    fse = FileSystemEntity.typeSync(path);
    return (fse != FileSystemEntityType.notFound);
    break;
    default:
    Config.debugLogger.e('stdLibExists unknown scope: $scope');
  }
}
