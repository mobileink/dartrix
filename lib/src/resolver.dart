import 'dart:async';
import 'dart:io';
// import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
// import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';

var _log = Logger('resolver');

bool verifyExists(String fsePath) {
  // FileSystemEntityType
  var fse = FileSystemEntity.typeSync(fsePath);
  return (fse != FileSystemEntityType.notFound);
}

// Terminology:
// userDartConfigDir :  $HOME/.dart.d
// userPackageConfig2 : $HOME/.dart.d/.dart_tool/package_config.json

// Generally, 'pkg' means the target package, and 'package' is for types.
// Thus pkgName but pkgPackageConfig

// pgkPackageUriStr:  package:pkg_name (i.e. PackageUriStr for pkg)
// pkgName:  pkg_name  (packageUri without leading 'package:')
// pkgPackageConfig1Uri : Uri for packageConfig v 1 for pkg
//                        i.e. Uri for pkgRoot/.packages
// pkgPackageConfig2 : packageConfig version 2 for target package
// pkgRootUri : a file:/// Uri for package root of pkg
//              e.g. /Users/gar/mobileink/hello_template
//              used both to fetch templates and to spawn pkg

//FIXME: use PathSet?
// String _externalPkgPath;
// String _templatesRoot;

// Map<String, String> _externalTemplates;

// TODO: also check /etc/.dart.d/
Future<PackageConfig> getUserPackageConfig2() async {
  // _log.info('getUserPackageConfig2');
  // get platform-independent $HOME
  //Map<String, String>
  var envVars = Platform.environment;
  var home;
  if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  }
  // _log.info('\$HOME: $home');

  var dartConfigDirPath = home + '/.dart.d';
  if ( !verifyExists(dartConfigDirPath) ) {
    dartConfigDirPath = home + '/.dart';
    if ( !verifyExists(dartConfigDirPath) ) {
      _log.severe('dartConfigDirPath (~/.dart.d or ~/.dart) not found)');
      exit(0);
    }
  }
  // if (verbose) _log.info('found dartConfigDirPath: $dartConfigDirPath');
  Directory dartConfigDir;
  dartConfigDir = Directory(dartConfigDirPath);
  PackageConfig userPackageConfig2;
  // fn from package_config.package_config_discovery Package class
  userPackageConfig2 = await findPackageConfig(
    dartConfigDir,
    onError: (e) => _log.severe(e)
  );
  // _log.info('pcfg2: $userPackageConfig2');
  // _log.info('listing packages:');
  // userPackageConfig2.packages.forEach((pkg) => _log.fine('${pkg.name}'));
  return userPackageConfig2;
}

/// pkg arg:  package:foo_dartrix or pkg:foo_dartrix
Future<String> resolvePkgRoot(String pkg) async {
  // _log.finer('resolvePkgRoot: $pkg');
  // validate pkg string
  if (pkg.startsWith('package:') || pkg.startsWith('pkg:')) {
    // _log.info('foo');
  } else {
    _log.severe('Malformed package URI. Must begin with "package:" or "pkg:" URI: $pkg');
    exit(0);
  }

  // extract foo_bar from package:foo_bar | pkg:foo_bar
  // String
  var pkgName = pkg.replaceFirst(RegExp('^package:'), '');
  pkgName = pkgName.replaceFirst(RegExp('^pkg:'), '');
  // _log.fine('pkgName: $pkgName');

  // now we follow the configPackages to get the file url for the pkg

  // Step 1: get user's dart config (a packageConfig2)
  //PackageConfig
  var userPackageConfig2 = await getUserPackageConfig2();
  // _log.info('got userPackageConfig2: $userPackageConfig2');
  // userPackageConfig2.packages.forEach(
  //   (pkg) => print(pkg.name)
  // );

  // Step 2. pkgName is listed as a dep in the packageConfig2
  // _log.info('searching for $pkgName');
  Package pkgPackage;
  try {
    pkgPackage = userPackageConfig2.packages.singleWhere(
      (pkg) => pkg.name == pkgName);
  } catch (e) {
    _log.severe('Dartrix library package:$pkgName not found.');
    exit(0);
  }
  // _log.info('pkgPackage: $pkgPackage');
  // Step 3.  Get the (file) root of the package. We need this to
  // a) read the templates, and b) spawn the package.
  var pkgRootUri = pkgPackage.root;
  // _log.info('pkgPackage.root: ${pkgRootUri}');
  return pkgRootUri.path;
}

/// Decompose package ref into name (with _dartrix) and uri
/// A package Uri is composed of:
///     uri        e.g. package:foobar_myapp
///     fullName   e.g. foobar_myapp
///     name       e.g. foobar
Map<String,String> resolvePkgRef(String pkgRef) {
  print('resolvePkgRef: $pkgRef');
  // String pkgName;
  // String pkgPackageUriStr;
  var name;
  if (pkgRef.endsWith(Config.appSfx)) {
    name = pkgRef.replaceAll(RegExp('${Config.appSfx}\$'), '');
  } else {
    _log.severe('bad package suffix; should be ${Config.appSfx}');
    exit(0);
  }
  if (pkgRef.startsWith('package:')) {
    return {
      'name'    : name.replaceAll(RegExp('^package:'), ''),
      'fullName' : pkgRef.replaceAll(RegExp('^package:'), ''),
      'uri'     : pkgRef
    };
  } else {
    if (pkgRef.startsWith('pkg:')) {
      return {
        'name' : name.replaceAll(RegExp('^pkg:'), ''),
        'fullName' : pkgRef.replaceAll(RegExp('^pkg:'), ''),
        'uri'  : pkgRef.replaceAll(RegExp('^pkg:'), 'package:')
      };
    } else {
      // must be a path: uri
      return {'path': pkgRef};
    }
  }
}

Future<List<Package>> getPlugins(String suffix) async {
  //PackageConfig
  var userPkgConfig2 = await getUserPackageConfig2();
  var pkgs = userPkgConfig2.packages.toList();
  // if (verbose) _log.info('found ${pkgs.length} user packages');
  pkgs.retainWhere((pkg) => pkg.name.endsWith(suffix));
  // if (verbose) {
  //   _log.info('found ${pkgs.length} $suffix packages:');
  //   pkgs.forEach((pkg) {
  //       _log.info('${pkg.name} => ${pkg.root}');
  //   });
  // }
  return pkgs;
}

