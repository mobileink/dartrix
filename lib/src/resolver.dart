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
import 'package:dartrix/src/lister.dart';
import 'package:dartrix/src/utils.dart';
import 'package:dartrix/src/yaml.dart';

// var _log = Logger('resolver');

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
  // Config.logger.i('platformScriptPath, canonicalized: ${path.canonicalize(scriptPath)}');
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

/// get PackageConfig for ~/.dart.d/
//FIXME: rename to getHomePkgConfig
Future<PackageConfig> getUserPackageConfig2() async {
  Config.ppLogger.i('getUserPackageConfig2');

  var dartConfigDirPath = Config.home + '/.dartrix.d';
  if (!verifyExists(dartConfigDirPath)) {
    // dartConfigDirPath = Config.home + '/.dart';
    // if (!verifyExists(dartConfigDirPath)) {
    Config.ppLogger.e('dartConfigDirPath (~/.dart.d or ~/.dart) not found)');
    exit(0);
    // }
  }
  // if (Config.debug) {
  //   Config.ppLogger.v('found dartConfigDirPath: $dartConfigDirPath');
  // }
  Directory dartConfigDir;
  dartConfigDir = Directory(dartConfigDirPath);
  PackageConfig userPackageConfig2;
  // fn from package_config.package_config_discovery Package class

  try {
    // findPackageConfig loads `.dart_tool/package_config.json` (version 2) or a
    // `.packages` (version 1) file.
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
  if (Config.verbose) {
    Config.logger.i('fetching $uri from pub.dev...');
  }
  try {
    await runCmd(PubCmd(['cache', 'add', uri]), verbose: false);
  } catch (e) {
    Config.debugLogger.e(e);
    exit(0);
  }
  return uri;
}

// Future<List<Map>> getUserTemplates(String templateLibName) async {}

/// Resolves a [templateLibName] to a package spec.
///
/// Searches user, local, syscache, and pub.dev. Returns
/// the highest version. Result is map with keys name, version,
/// cache, and rootUri.
Future<List<Map>> resolvePkg(String templateLibName) async {
  // Config.debugLogger.d('resolvePkg: $templateLibName');

  switch (templateLibName) {
    case ':.':
    case ':here':
      return listHereLib();
      break;
    case ':d':
    case ':dartrix': // Config.appName :
      return [
        {
          'name': Config.appName,
          'version': Config.appVersion,
          'docstring': 'Builtin templates',
          'scope': 'builtin',
          'rootUri': path.canonicalize(Config.appPkgRoot)
        }
      ];
      break;
    case ':h':
    case ':home':
    case ':u':
    case ':user':
      return listUserLib();
      break;
    case ':l':
    case ':local': // return listLocalLib();
      //FIXME: verify it exists
      return [
        {
          'name': ':local', //'dartrix',
          'version': null,
          'docstring': 'Local template library',
          'scope': 'local',
          'rootUri': '/usr/local/share/dartrix'
        }
      ];
    default:
      if (templateLibName.startsWith(':')) {
        return await resolvePluginPkg(templateLibName.substring(1));
      } else {
        Config.prodLogger.e(
            'Invalid library name ${templateLibName}. Library names must be passed with leading \':\'. Try \':${templateLibName}\'');
        return null;
      }
  }
}

Future<List<Map>> resolvePluginPkg(String templateLibName) async {
  // Config.debugLogger.d('resolvePluginPkg $templateLibName');
  // 1. look in ~/.dartrix.d/.yaml, libraries: entry
  // Rule: if listed as user lib with path it wins

  var userYaml = getUserYaml();
  if (userYaml != null) {
    var lib;
    try {
      lib = userYaml.libraries.singleWhere((lib) {
        return (lib.name == templateLibName + Config.appSfx);
      }, orElse: () => null);
    } catch (e) {
      Config.ppLogger.e(e);
      // muliple matches, should not happen
      Config.ppLogger.e(
          'User config file (${Config.home}/.dartrix.d/.yaml}) contains duplicate library entries for \'${templateLibName}_dartrix\'. Disallowed.');
      exit(1);
    }
    if (lib != null) {
      var r = {'name': lib.name, 'rootUri': lib.path};
      return [r];
    }
  }

  // // Step 1: get user's dart config (a packageConfig2)
  // //PackageConfig
  // var userPackageConfig2 = await getUserPackageConfig2();
  // // Step 2. pkgName is listed as a dep in the packageConfig2
  // // Package

  var templatePkgName = templateLibName + Config.appSfx; // '_dartrix';
  // var pkgName = templateLibName + Config.appSfx; // '_dartrix';
  // var _pkgList;
  // //Package
  // var pkgPackage;
  // try {
  //   pkgPackage =
  //       userPackageConfig2.packages.singleWhere((pkg) => pkg.name == pkgName);
  //   // this is ok - pkg config can only contain one copy of a dep
  //   _pkgList = [
  //     {
  //       'name': pkgPackage.name,
  //       'version': 'Y',
  //       'cache': 'dartrix',
  //       'rootUri': pkgPackage.root.path
  //     }
  //   ];
  // Config.ppLogger.i('found in user pkgconfig: $_pkgList');
  // } catch (e) {
  //   if (!(e.message.startsWith('No element'))) {
  //     Config.prodLogger.e(e);
  //     exit(0);
  //   }

  //   if (Config.debug) {
  //     Config.logger.d(
  //         'dartrix library pkg \'$pkgName\' not in usercache; checking syscache.');
  //   }

  var _pkgList = await searchSysCache(templatePkgName);
  if (_pkgList.isEmpty) {
    if (Config.debug) {
      Config.logger.d(
          'dartrix library pkg \'$templatePkgName\' not in syscache; checking pub.dev.');
    }
    //FIXME: only if Config.searchPubDev
    // download and install in syscache
    await fetchPackage(templatePkgName);
    // now we should find it
    var sysPkgList = await searchSysCache(templatePkgName);
    if (sysPkgList.isEmpty) {
      Config.prodLogger.i('Plugin package \'$templatePkgName\' not found.');
      if (templatePkgName.startsWith('dartrix')) {
        Config.prodLogger.i(
            'Did you forget a semi-colon? Try \':dartrix\' (or just \':d\').');
      }
    }
    // Config.ppLogger.d('fetchPackage: $sysPkgList');
    // return sysPkgList.first; //['uri']; //.path;
    // pkg = sysPkgList.first;
    _pkgList = sysPkgList;
  } else {
    if (Config.debug) {
      Config.logger.d(
          'found ${_pkgList.length} occurrences of $templatePkgName in syscache: $_pkgList');
    }
    // return p.first; //['uri']; //.path + '/'; //FIXME: remove this hack
    // pkg = p.first;
    return _pkgList;
  }
  // }
  // Config.libPkgRoot = pkg['rootUri'];
  // Config.ppLogger.d('resolved pkgList: $_pkgList');
  return _pkgList; // ['rootUri']; // pkgRootUri.path;
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
  // DO NOT omit this type annotation, doing so breaks the code
  List<Map> syscachePkgs = [];
  if (uri == null) {
    // null uri means get all
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
  } else {
    syscache.retainWhere((pkg) => path.basename(pkg.path).startsWith(uri));
  }
  var ty;
  syscache.forEach((pkg) async {
    // print('plugin path: ${pkg.path}');
    ty = loadYamlFileSync(pkg.path + '/pubspec.yaml');
    var pspec = {
      'name': path.basename(pkg.path).split('-')[0],
      'version': path.basename(pkg.path).split('-')[1],
      'docstring': ty['description'], //FIXME
      'rootUri': path.canonicalize(pkg.path),
      'scope': 'sys'
    };
    syscachePkgs.add(pspec);
  });
  // Config.ppLogger.d('syscachePkgs: $syscachePkgs');
  // return syscachePkgs.toList();

  // var ty;
  // syscache.forEach((pkg) async {
  //   // print('plugin path: ${pkg.path}');
  //   ty = loadYamlFileSync(pkg.path + '/pubspec.yaml');
  //   var pspec = {
  //     'name': path.basename(pkg.path).split('-')[0],
  //     'version': path.basename(pkg.path).split('-')[1],
  //     'docstring': ty['description'], //FIXME
  //     'rootUri': pkg.path,
  //     'scope': 'sys'
  //   };
  //   syscachePkgs.add(pspec);
  // });
  // syscachePkgs = [
  //   for (var pkg in syscache)

  //     {
  //       'name': path.basename(pkg.path).split('-')[0],
  //       'version': path.basename(pkg.path).split('-')[1],
  //       // 'docstring' : '

  //       'rootUri': pkg.path,
  //       'scope': 'sys'
  //     }
  // ];
  // }
  // Config.debugLogger.d('SYSCACHE: $syscachePkgs');
  return syscachePkgs; //.toList();
}

Future<List<Map<String, String>>> downloadPkgSpecs(Set pset) async {
  // omitting this type decl breaks the code
  var devPubPlugins = List<Map<String, String>>();
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
      'docstring': body['latest']['pubspec']['docstring'],
      'scope': 'pubdev',
      'docstring': body['latest']['pubspec']['description']
    });
  }
  ;
  // await fn();
  // print(devPubPlugins);
  return devPubPlugins;
}

Future<List<Map<String, String>>> getPubDevPlugins(String url) async {
  // Config.ppLogger.v('getPubDevPlugins $url');
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
  print('getPluginVersion $rootPath');
  var f = path.canonicalize(rootPath + '/pubspec.yaml');
  var yaml = loadYamlFileSync(f);
  return yaml['version'];
}

// String getDocStringFromPkg(String libName, String uri) {
//   Config.ppLogger.v('getDocStringFromPkg $libName, $uri');
//   // var rootDir = pkgName.root.path;
//   // var libName = pkg.name.replaceFirst(RegExp('_dartrix'), '');
//   var docstringName = libName + '.docstring';
//   var docstring = File(uri + '/' + docstringName).readAsStringSync();
//   //TODO: break long lines
//   return docstring;
// }

// String getTLibDocString(String templatesRoot, Directory tdir) {
//   Config.ppLogger.d('getDocString $templatesRoot, $tdir');
//   if (Config.tLibDocString != null) {
//     return Config.tLibDocString;
//   }
//   var template = path.basename(tdir.path);
//   var docString;
//   try {
//     docString =
//         File(templatesRoot + '/' + template + '.docstring').readAsStringSync();
//     // } on FileSystemException {
//   } catch (e) {
//     // docString = warningPen('${template}.docstring not found');
//     if (Config.debug) {
//       Config.debugLogger.w(e);
//       // } else {
//       //   Config.logger.w(e);
//     }
//   }
//   return docString;
// }

// String getTemplateDocString(Directory tdir) {
//   // Config.debugLogger.d('getTemplateDocString, $tdir');
//   if (Config.tLibDocString != null) {
//     return Config.tLibDocString;
//   }
//   var templateYaml = getTemplateYaml(tdir.path);
//   // Config.ppLogger.d('t docstring: ${templateYaml.docstring}');
//   return templateYaml.docstring;
// }

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
