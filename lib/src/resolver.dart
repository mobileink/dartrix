import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/cmd_run.dart';
// import 'package:process_run/process_run.dart';
// import 'package:sprintf/sprintf.dart';

import 'package:dartrix/src/config.dart';
// import 'package:dartrix/src/debug.dart' as debug;
// import 'package:dartrix/src/utils.dart';

// var _log = Logger('resolver');

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

// Get root file uri for pkg of running script (app).
void setAppPkgRoot(String app) async {
  // Config.ppLogger.v('getAppPkgRoot');

  // getting launch directory for script is not enough,
  // since the script may be run from some other place, as
  // in the case of pub global installed binaries launched
  // from ~/.pub-cache/global_packages.
  // So we need to find the pkg root directory, which is
  // recorded in ./.packages, which is in the launch dir.

  var currentIsoPkgConfigUri;
  try {
    currentIsoPkgConfigUri = await Isolate.packageConfig;
  } catch (e) {
    print(e);
    Config.ppLogger.e(e);
    exit(0);
  }
  Config.isoHome = path.dirname(currentIsoPkgConfigUri.path);
  // if (Config.debug) {
  //   // e.g. file:///Users/gar/mobileink/dartrix/.packages
  //   Config.ppLogger.v('$app app pkg cfg: $currentIsoPkgConfigUri');
  // }
  // Isolate.packageConfig finds the version 1 .packages file;
  // use that to get the PackageConfig and you get the contents
  // of the version 2 .dart_tool/package_config.json
  // findPackageConfigUri is a fn in package:package_confg
  //PackageConfig
  var pkgConfig = await findPackageConfigUri(currentIsoPkgConfigUri);
  // if (Config.debug) {
  //   // PackageConfig is an object containing list of deps
  //   // Config.debugLogger.d('current iso PackageConfig: $pkgConfig');
  //   debug.debugPackageConfig(pkgConfig);
  // }
  // Now we need to find the dep entry for the app.
  // 'Package': object with keys name, packageUriRoot, and root (=pkgRoot)
  // Package
  var appConfig = pkgConfig.packages.firstWhere((pkg) {
    return pkg.name == Config.appName;
  });
  // Config.logger.i('appConfig: ${appConfig.name} : ${appConfig.root}');
  //String
  Config.appPkgRoot = appConfig.root.path;
  // return Config.appPkgRoot;
}

void setBuiltinTemplatesRoot() async {
  // print('X resolveBuiltinTemplatesRoot');
  // Procedure: get path to app pkg root (as opposed to the package UriRoot,
  // which is the package's lib/ dir).  In this case the package is
  // package:dartrix; the pkg root is ~/mobileink/dartrix, and the package
  // UriRoot is ~/mobileink/dartrix/lib.  The templates are in the package
  // root, not the package UriRoot.

  // So to find the templates, we need to find the package root.

  // Location fo currently running script does not work - pub global separates
  // the script from the project dir structure.

  // Location of "currently running Dart script": dart:io/Platform.script
  // Current Working Directory: dart:io/Directory.current
  // Current Isolate

  // Config.logger.i('cwd: ${Directory.current}');
  // e.g. Directory: '/Users/gar/tmp/dartrix'

  // String scriptPath = path.prettyUri(Platform.script.toString());
  // relative path, e.g. ../../mobileink/dartrix/bin/new.dart
  // Config.logger.i('platformScriptPath: ${scriptPath}');
  // Config.logger.i('platformScriptPath, normalized: ${path.normalize(scriptPath)}');
  // Config.logger.i('platformScriptPath, canonical: ${path.canonicalize(scriptPath)}');

  //Uri
  var currentIsoPkgConfigUri;
  try {
    currentIsoPkgConfigUri = await Isolate.packageConfig;
  } catch (e) {
    print(e);
  }
  if (Config.debug) {
    // e.g. file:///Users/gar/mobileink/dartrix/.packages
    // Config.debugLogger.d('currentIsoPkgConfigUri: $currentIsoPkgConfigUri');
  }
  // Isolate.packageConfig finds the version 1 .packages file;
  // use that to get the PackageConfig and you get the contents
  // of the version 2 .dart_tool/package_config.json
  // findPackageConfigUri is a fn in package:package_confg
  //PackageConfig
  var pkgConfig = await findPackageConfigUri(currentIsoPkgConfigUri);
  // PackageConfig is an object containing list of deps

  // 'Package': 'map' with keys name, packageUriRoot, and root (=pkgRoot)
  // Package
  var appConfig = pkgConfig.packages.firstWhere((pkg) {
    return pkg.name == Config.appName;
  });
  // Config.logger.i('appConfig: ${appConfig.name} : ${appConfig.root}');
  //String
  var templatesRoot = appConfig.root.path + '/templates';
  // using scriptPath is undoubtedly more efficient
  // String templatesRoot = path.dirname(scriptPath) + '/../templates';
  Config.builtinTemplatesRoot = path.canonicalize(templatesRoot);
  // Config.logger.i('templatesRoot: $templatesRoot');
}

// TODO: also check /etc/.dart.d/
Future<PackageConfig> getUserPackageConfig2() async {
  // Config.logger.i('getUserPackageConfig2');
  // get platform-independent $HOME
  //Map<String, String>
  // var envVars = Platform.environment;
  // var home;
  // if (Platform.isMacOS) {
  //   home = envVars['HOME'];
  // } else if (Platform.isLinux) {
  //   home = envVars['HOME'];
  // } else if (Platform.isWindows) {
  //   home = envVars['UserProfile'];
  // }
  // Config.logger.i('\$HOME: $home');

  var dartConfigDirPath = Config.home + '/.dart.d';
  if (!verifyExists(dartConfigDirPath)) {
    dartConfigDirPath = Config.home + '/.dart';
    if (!verifyExists(dartConfigDirPath)) {
      Config.ppLogger.e('dartConfigDirPath (~/.dart.d or ~/.dart) not found)');
      exit(0);
    }
  }
  // if (Config.debug) {
  //   Config.ppLogger.v('found dartConfigDirPath: $dartConfigDirPath');
  // }
  Directory dartConfigDir;
  dartConfigDir = Directory(dartConfigDirPath);
  PackageConfig userPackageConfig2;
  // fn from package_config.package_config_discovery Package class

  try {
    userPackageConfig2 = await findPackageConfig(dartConfigDir);
    // onError: (e) => Config.logger.e(e));
  } catch (e) {
    Config.ppLogger.e(e);
    exit(0);
  }
  // print('pcfg2: $userPackageConfig2');
  // Config.logger.i('listing packages:');
  // userPackageConfig2.packages.forEach((pkg) => _log.fine('${pkg.name}'));
  return userPackageConfig2;
}

Future<String> fetchPackage(String uri) async {
  // Config.ppLogger.v('fetchPackage $uri');
  // if (Config.debug) {
  Config.logger.i('fetching $uri from pub.dev...');
  // }
  try {
    await runCmd(PubCmd(['cache', 'add', uri]), verbose: false);
  } catch (e) {
    Config.debugLogger.e(e);
    exit(0);
  }
  return uri;
}

/// pkg arg:  package:foo_dartrix or pkg:foo_dartrix
/// returns pkg root (dir containing .packages file)
Future<Map> resolvePkg(String libName) async {
  // Config.ppLogger.d('resolvePkgRoot: $libName');

  if (libName == 'dartrix') {
    return {
      'name': 'dartrix',
      'version': Config.appVersion,
      'cache': null,
      'rootUri': Config.appPkgRoot // await getAppPkgRoot(libName);
    };
  }

  // validate libName string
  // if (libName.startsWith('package:') || libName.startsWith('pkg:')) {
  //   // Config.logger.i('foo');
  // } else {
  //   Config.ppLogger.e(
  //       'Malformed package URI. Must begin with "package:" or "pkg:" URI: $libName');
  //   exit(0);
  // }

  // extract foo_bar from package:foo_bar | pkg:foo_bar
  // String
  // var pkgName = libName.replaceFirst(RegExp('^package:'), '');
  // pkgName = pkgName.replaceFirst(RegExp('^pkg:'), '');
  // _log.fine('pkgName: $pkgName');

  // now we follow the configPackages to get the file url for the pkg

  // Step 1: get user's dart config (a packageConfig2)
  //PackageConfig
  var userPackageConfig2 = await getUserPackageConfig2();
  // Step 2. pkgName is listed as a dep in the packageConfig2
  // Package

  var pkgName = libName + '_dartrix';
  //Package
  var pkgPackage;
  try {
    pkgPackage =
        userPackageConfig2.packages.singleWhere((pkg) => pkg.name == pkgName);
  } catch (e) {
    if (!(e.message.startsWith('No element'))) {
      Config.prodLogger.e(e);
      exit(0);
    }

    if (Config.debug) {
      Config.logger.d(
          'dartrix library pkg \'$pkgName\' not in usercache; checking syscache.');
    }

    var p = await searchSysCache(pkgName);
    if (p.isEmpty) {
      if (Config.debug) {
        Config.logger.d(
            'dartrix library pkg \'$pkgName\' not in syscache; checking pub.dev.');
      }
      // download and install in syscache
      await fetchPackage(pkgName);
      // now we should find it
      var newp = await searchSysCache(pkgName);
      if (newp.isEmpty) {
        Config.debugLogger.e('giving up');
      }
      // Config.ppLogger.d('fetchPackage: $newp');
      return newp.first; //['uri']; //.path;
    } else {
      if (Config.debug) {
        Config.logger.d('found $pkgName in syscache: $p');
      }
      return p.first; //['uri']; //.path + '/'; //FIXME: remove this hack
    }
  }
  // Config.logger.i('pkgPackage: $pkgPackage');
  // Step 3.  Get the (file) root of the package. We need this to
  // a) read the templates, and b) spawn the package.
  // var pkgRootUri = pkgPackage.root;
  // Config.logger.i('pkgPackage.root: ${pkgRootUri}');
  var pkg = {
    'name': pkgPackage.name,
    'version': 'Y',
    'cache': 'dartrix',
    'rootUri': pkgPackage.root.path
  };
  return pkg; // ['rootUri']; // pkgRootUri.path;
}

/// Decompose package ref into name (with _dartrix) and uri
/// A package Uri is composed of:
///     uri        e.g. package:foobar_myapp
///     fullName   e.g. foobar_myapp
///     name       e.g. foobar
Map<String, String> resolvePkgRef(String pkgRef) {
  print('resolvePkgRef: $pkgRef');
  // String pkgName;
  // String pkgPackageUriStr;
  var name;
  if (pkgRef.endsWith(Config.appSfx)) {
    name = pkgRef.replaceAll(RegExp('${Config.appSfx}\$'), '');
  } else {
    Config.ppLogger.e('bad package suffix; should be ${Config.appSfx}');
    exit(0);
  }
  if (pkgRef.startsWith('package:')) {
    return {
      'name': name.replaceAll(RegExp('^package:'), ''),
      'fullName': pkgRef.replaceAll(RegExp('^package:'), ''),
      'uri': pkgRef
    };
  } else {
    if (pkgRef.startsWith('pkg:')) {
      return {
        'name': name.replaceAll(RegExp('^pkg:'), ''),
        'fullName': pkgRef.replaceAll(RegExp('^pkg:'), ''),
        'uri': pkgRef.replaceAll(RegExp('^pkg:'), 'package:')
      };
    } else {
      // must be a path: uri
      return {'path': pkgRef};
    }
  }
}

//FIXME: bettr name
Future<List<Map>> searchSysCache(String uri) async {
  // Config.ppLogger.d('searchSysCache $uri');
  var syscacheRoot = Config.home + '/.pub-cache/hosted/pub.dartlang.org';
  var syscache = Directory(syscacheRoot).listSync();
  if (uri == null) {
    var base;
    var parts;
    // var version;
    syscache.retainWhere((pkg) {
      parts = path.basename(pkg.path).split('-');
      base = parts[0];
      // Config.logger.v(base);
      return base.endsWith(Config.appSfx);
    });
    if (Config.debug) {
      Config.logger
          .d('found ${syscache.length} plugins in syscache ($syscacheRoot).');
    }
    var syscachePkgs = [
      for (var pkg in syscache)
        {
          'name': path.basename(pkg.path).split('-')[0],
          'version': path.basename(pkg.path).split('-')[1],
          'rootUri': pkg.path,
          'syscache': true
        }
    ];
    // Config.ppLogger.d('syscachePkgs: $syscachePkgs');
    return syscachePkgs.toList();
  } else {
    syscache.retainWhere((pkg) => path.basename(pkg.path).startsWith(uri));
    var syscachePkgs = [
      for (var pkg in syscache)
        {
          'name': path.basename(pkg.path).split('-')[0],
          'version': path.basename(pkg.path).split('-')[1],
          'rootUri': pkg.path,
          'cache': 'sys'
        }
    ];
    return syscachePkgs.toList();
    // if (syscache.isEmpty) {
    //   return null;
    // } else {
    //   // Config.ppLogger.v('count: ${syscache.length}');
    //   return syscache.first.path;
    // }
  }
}

Future<List<Map<String, String>>> downloadPkgSpecs(Set pset) async {
  List<Map<String, String>> // omitting this type decl breaks the code
      devPubPlugins = [];
  // var fn = () async {
  for (var pkg in pset) {
    var url = 'https://pub.dartlang.org/api/packages/' + pkg + '_dartrix';
    var response = await http.get(url);
    // print(response.body);
    var body = json.decode(response.body);
    // Config.ppLogger.v('name: ${body["name"]}');
    devPubPlugins.add({
      'name': body['name'],
      'version': body['latest']['pubspec']['version'],
      'docstring': body['latest']['pubspec']['description']
    });
  }
  ;
  // await fn();
  // print(devPubPlugins);
  return devPubPlugins;
}

Future<List<Map<String, String>>> getPubDevPlugins(String url) async {
  // url ??= 'https://pub.dartlang.org/api/packages?q=_dartrix';
  url ??= 'https://pub.dev/dart/packages?q=dartrix';
  // response is map of two keys, next_url and packages
  var response = await http.get(url);
  // print('Response status: ${response.statusCode}');
  // print('Response body: ${response.body}');

  //RegExp
  var regexp = RegExp(r'packages/(.*?)(?=_dartrix)');
  // Iterable<RegExpMatch>
  var matches = regexp.allMatches(response.body);
  var pkgs = [
    for (var match in matches) match.group(1),
  ];
  var pset = Set.from(pkgs);
  if (Config.debug) {
    Config.logger.d('found ${pset.length} plugins on pub.dev');
  }

  // Config.ppLogger.v('$pset');
  //List<Map<String,String>>
  var result = await downloadPkgSpecs(pset);
  if (Config.debug) {
    Config.ppLogger.d('downloaded: $result');
  }

  return result;
  // var body = json.decode(response.body);
  // var pkgs = body['packages'];
  // // print('body: ${response.body}');
  // print('Response pkg count: ${pkgs.length}');
  // print('pkg 37: ${pkgs[37]}');
  // pkgs.forEach((pkg) => print(pkg['name']));
  // pkgs.retainWhere((pkg) {
  //   return pkg['name'].endsWith('_dartrix') ? true : false;
  // });
  // print('dartrix pkgs $pkgs,  rtt: ${pkgs.runtimeType}');
  // // pkgs.toList().sort((a, b) => (a.name.compareTo(b.name)) as int);
  // pkgs.forEach((pkg) => print('pkg $pkg'));
  // if (body['next_url'] != null) {
  //   getPubDevPlugins(body['next_url'+ '?q=dartrix']);
  // }
  // return pkgs;
}

String getPluginVersion(String rootPath) {
  // print('getPluginVersion $rootPath');
  var f = path.normalize(rootPath + '/pubspec.yaml');
  var yaml = loadYamlFileSync(f);
  return yaml['version'];
}

Future<List<Map>> getPlugins(String suffix) async {
  // Config.debugLogger.d('getPlugins $suffix');
  // 1. usercache
  //PackageConfig
  var userPkgConfig2 = await getUserPackageConfig2();
  var pkgs = userPkgConfig2.packages.toList();
  // if (verbose) Config.logger.i('found ${pkgs.length} user packages');
  pkgs.retainWhere((pkg) => pkg.name.endsWith(suffix));
  // if (verbose) {
  //   Config.logger.i('found ${pkgs.length} $suffix packages:');
  //   pkgs.forEach((pkg) {
  //       Config.logger.i('${pkg.name} => ${pkg.root}');
  //   });
  // }
  List<Map> userPkgs;
  if (pkgs.isNotEmpty) {
    // if (Config.debug) {
    //   pkgs.forEach((pkg) => Config.ppLogger.d('userPkg: ${pkg.name}'));
    // }
    if (Config.debug) {}
    userPkgs = [
      for (var p in pkgs)
        {
          'name': p.name,
          'version': getPluginVersion(path.dirname(p.packageUriRoot.path)),
          'cache': 'userX',
          ...(p.packageUriRoot.path.contains('.pub-cache')
              ? {'rootUri': path.dirname(p.packageUriRoot.path)}
              : {'path': path.dirname(p.packageUriRoot.path)}),
        }
    ];
  }
  if (Config.debug) {
    Config.logger
        .d('found ${pkgs.length} plugins in usercache (${Config.userCache})');
  }

  // Config.ppLogger.v('userpkg: $userPkgs');

  // 2. syscache
  var sysPkgs = await searchSysCache(null); // find all
  // if (Config.verbose) {
  //   Config.ppLogger.i('Found in syscache: $pkgDirs');
  // }

  // var base;
  // var sysPkgs = [
  //   for (var dir in pkgDirs)
  //     {
  //       'name': path.basename(dir.path).split('-')[0],
  //       'rootUri': dir.path,
  //       'syscache': 'true'
  //     }
  // ];
  if (sysPkgs != null) {
    userPkgs.addAll(sysPkgs);
  }

  var pubDevPlugins = [];
  if (Config.searchPubDev) {
    pubDevPlugins = await getPubDevPlugins(null);
  }

  // Config.ppLogger.v('userPkgs: $userPkgs');
  // Config.ppLogger.v('pubDevPlugins: $pubDevPlugins');
  List<Map> allPlugins = List.from(pubDevPlugins);
  allPlugins.addAll(userPkgs);
  // print('allPlugins: $allPlugins');

  // now remove pub.dev plugins that are already installed
  // allPlugins = allPlugins.fold([], (prev, elt) {
  //   var i = prev.indexWhere((e) => e['name'] == elt['name']);
  //   if (i < 0) {
  //     prev.add(elt);
  //   } else {
  //     if (prev[i]['rootUri'] == null) {
  //       // print('removing ${prev[i]}');
  //       prev.removeAt(i);
  //       prev.add(elt);
  //     }
  //   }
  //   return prev;
  // });
  // print('new allPlugins: $allPlugins');

  allPlugins.sort((a, b) => a['name'].compareTo(b['name']));

  if (userPkgs != null) {
    if (allPlugins != null) {
      return allPlugins;
    } else {
      return userPkgs;
    }
  } else {
    return allPlugins;
  }
}

String getDocStringFromPkg(String libName, String uri) {
  // Config.ppLogger.v('getDocStringFromPkg $libName, $uri');
  // var rootDir = pkgName.root.path;
  // var libName = pkg.name.replaceFirst(RegExp('_dartrix'), '');
  var docstringName = libName + '.docstring';
  var docstring = File(uri + '/' + docstringName).readAsStringSync();
  //TODO: break long lines
  return docstring;
}

String getDocString(String templatesRoot, Directory tdir) {
  var template = path.basename(tdir.path);
  var docString;
  try {
    docString =
        File(templatesRoot + '/' + template + '.docstring').readAsStringSync();
    // } on FileSystemException {
  } catch (e) {
    // docString = warningPen('${template}.docstring not found');
    if (Config.debug) {
      Config.debugLogger.w(e);
      // } else {
      //   Config.logger.w(e);
    }
  }
  return docString;
}

//FIXME: which file does this belong in?
// void printAvailableLibs() async {
//   //CommandRunner runner) async {
//   // {template : docstring }

//   print('\nLibraries:');
//   //List<Package>
//   var pkgs = await getPlugins('_dartrix');
//   print('\t${sprintf("%-18s", ["dartrix"])} Builtin templates');
//   pkgs.forEach((pkg) {
//     var pkgName = pkg.name.replaceFirst(RegExp('_dartrix\$'), '');
//     var docString = getDocStringFromPkg(pkg);
//     pkgName = sprintf('%-18s', [pkgName]);
//     print('\t${pkgName} ${docString}');
//   });
//   print('');
// }

/// return map of templates for pkgRoot
/// map keys:  name, root, docstring
Future<Map> getTemplatesMap(String pkgRoot) async {
  var templatesRoot;
  if (pkgRoot == null) {
    templatesRoot =
        Config.builtinTemplatesRoot; //await setBuiltinTemplatesRoot();
  } else {
    templatesRoot = pkgRoot + '/templates';
  }
  var templates = Directory(templatesRoot).listSync()
    ..retainWhere((f) => f is Directory);

  var tmap = {
    for (var tdir in templates)
      path.basename(tdir.path): {
        'root': tdir.path,
        'docstring': getDocString(templatesRoot, tdir)
      },
  };
  return tmap;
}
