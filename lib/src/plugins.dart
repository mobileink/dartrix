import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:package_config/package_config.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/utils.dart';

var _log = Logger('plugins');

// Terminology:
// userDartConfigDir :  $HOME/.dart.d
// userPackageConfig2 : $HOME/.dart.d/.dart_tool/package_config.json

// Generally, 'pkg' means the target package, and 'package' is for types.
// Thus pkgName but pkgPackageConfig

// pgkPackageUriStr:  package:pkg_name (i.e. PackageUriStr for pkg)
// pkgName:  pkg_name  (packageUri without leading "package:")
// pkgPackageConfig1Uri : Uri for packageConfig v 1 for pkg
//                        i.e. Uri for pkgRoot/.packages
// pkgPackageConfig2 : packageConfig version 2 for target package
// pkgRootUri : a file:/// Uri for package root of pkg
//              e.g. /Users/gar/mobileink/hello_template
//              used both to fetch templates and to spawn pkg

//FIXME: use PathSet?
String _externalPkgPath;
String _templatesRoot;

Map<String, String> _externalTemplates;

/// Get $HOME/.dart.d/.dart_tool/package_config.json
Future<PackageConfig> getUserPackageConfig2() async {
  // get platform-independent $HOME
  Map<String, String> envVars = Platform.environment;
  var home;
  if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  }
  _log.info("\$HOME: $home");

  var dartConfigDirPath = home + "/.dart.d";
  if ( !verifyExists(dartConfigDirPath) ) {
    dartConfigDirPath = home + "/.dart";
    if ( !verifyExists(dartConfigDirPath) ) {
      _log.severe("dartConfigDirPath (~/.dart.d or ~/.dart) not found)");
      exit(0);
    }
  }
  _log.info("found dartConfigDirPath: $dartConfigDirPath");
  Directory dartConfigDir = Directory(dartConfigDirPath);
  PackageConfig userPackageConfig2 = await findPackageConfig(dartConfigDir);
  _log.info("pcfg2: $userPackageConfig2");
  // _log.info("listing packages:");
  // userPackageConfig2.packages.forEach((pkg) => _log.fine("${pkg.name}"));

  return userPackageConfig2;

  // Deprecated: .packages is version 1.
  // var homePackagesPath = dartConfigDirPath + "/.packages";
  // // var homePackagesPath = dartConfigDirPath + "/.dart_tool/package_config.json";
  // var homeYaml = dartConfigDirPath + "/pubspec.yaml";
  // if ( !verifyExists(homePackagesPath) ) {
  //   if ( !verifyExists(homeYaml) ) {
  //     _log.severe("\n\tNeither ${infoPen(homePackagesPath)} nor ${infoPen(homeYaml)} found.\n\tCreate ${homeYaml} and run '\$ pub get' in ${dartConfigDirPath}.\n\tThis will create ${homePackagesPath}.\n\tFor more info run: '\$ pub global run dartrix:doc'");
  //     exit(0);
  //   } else {
  //     _log.severe("\n\t${infoPen(homePackagesPath)} not found, but ${infoPen(homeYaml)} found.\n\tPlease run '\$ pub get' in $dartConfigDirPath.");
  //     exit(0);
  //   }
  // }
  // _log.info("found .packages file at ${homePackagesPath}");

  // var homePackageConfigUri = Uri.parse(homePackagesPath);
  // var resolver = await SyncPackageResolver.loadConfig(homePackageConfigUri);
  // _log.info("resolver: $resolver");
  // _log.info("pkg root: ${resolver.packageRoot}");
  // // _log.info("pkg configMap: ${resolver.packageConfigMap}");
  // // _log.info("pkg configUri: ${resolver.packageConfigUri}");
}

void initXTemplates(String packagePath) {
  // _log.finer("initXTemplates: $packagePath");
  // packagePath = path.canonicalize(packagePath);
  // _log.finer("packagePath: ${packagePath}");
  // packagePath = path.prettyUri(_path);
  // _log.finer("pretty packagePath: ${packagePath}");

  _externalPkgPath = path.canonicalize(packagePath);
  // _log.finer("_externalPkgPath path: $_externalPkgPath");

  String templatesRoot = packagePath + "/templates";
  _templatesRoot = path.canonicalize(templatesRoot);

  List externals = Directory(_templatesRoot).listSync();
  externals.retainWhere((f) => f is Directory);
  // _log.finer("getExternalTemplates: $externals");
  _externalTemplates = Map.fromIterable(
    externals,
    key: (dir) => path.basename(dir.path),
    value: (dir) => dir.path.replaceFirst(_templatesRoot, '')
  );
}

/// This routine is invoke when the external isolate returns data.
void _generateFromPath(dynamic _xData) {
  _log.finer("_generateFromPath: $_xData");
  // _log.finer("_externalPkgPath path: $_externalPkgPath");
  // _log.finer("_templatesRoot path: $_templatesRoot");
  // _log.finer("_externalTemplates: $_externalTemplates");

  xData = _xData;
  // step one: merge data maps
  if (_xData['dartrix']['mergeData']) {
    mergeExternalData(tData, _xData);
    if (tData['class'] != argParser.getDefault("class")) {

    }
  }
  mergeUserOptions();

  if (debug.debug) debug.debugData(null);

  if (debug.debug) debug.debugPathRewriting(_xData);
    // get out path
  var outPathPrefix = tData['outpath'];

  // iterate over template fileset
  var t = tData['template'];
  var _templateRoot = _templatesRoot + _externalTemplates[tData['template']];
  // _log.fine("_templateRoot: $_templateRoot");
  List tFileset = Directory(_templateRoot).listSync(recursive:true);
  tFileset.removeWhere((f) => f.path.endsWith("~"));
  tFileset.retainWhere((f) => f is File);

  if (debug.verbose) _log.fine("Generating files from templates and copying assets (cwd: ${Directory.current.path}):");

  tFileset.forEach((tfile) {
      // _log.finer("tfile: $tfile");
      var outSubpath = path.normalize(
        outPathPrefix + tfile.path.replaceFirst(_templatesRoot, '')
      );
      outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');
      // _log.finer("outSubpath: $outSubpath");
      outSubpath = path.normalize(rewritePath(outSubpath));

      // exists?
      if ( !tData['dartrix']['force'] ) {
        var exists = FileSystemEntity.typeSync(outSubpath);
        if (exists != FileSystemEntityType.notFound) {
          _log.severe("ERROR: $outSubpath already exists; cancelling. Use -f to force overwrite.");
          exit(0);
        }
      }
      var dirname = path.dirname(outSubpath);
      // _log.finer("dirname: $dirname");
      Directory(dirname).createSync(recursive:true);

      if (debug.verbose) _log.fine("   " + tfile.path);
      if (tfile.path.endsWith("mustache")) {
        var contents;
        contents = tfile.readAsStringSync();
        var template = Template(contents,
          name: outSubpath,
          htmlEscapeValues: false);
        var newContents = template.renderString(tData);
        // _log.finer(newContents);
        if (debug.verbose) _log.fine("=> ${Directory.current.path}/$outSubpath");
        File(outSubpath).writeAsStringSync(newContents);
      } else {
        if (debug.verbose) _log.fine("=> ${Directory.current.path}/$outSubpath");
        tfile.copySync(outSubpath);
      }
  });
}

void spawnExternalFromPath(String pkg, String template, List<String> args)
async {
  // _log.finer("spawnExternalFromPath: $pkg");

  // 1. this constructs the file:// url for the pkg as _externalPkgPath
  // and a list of its template roots in _exterternalTemplates.
  String packagePath= pkg.replaceFirst("path:", '');
  initXTemplates(packagePath);

  // 2. get the .packages file for the pkg. we need this because the pkg may
  // have deps that dartrix does not have.  It will be passed as the
  // packageConfig parm to spawnUri.
  var pkgConfigMap = _externalPkgPath + "/.packages";
  // verify:
  FileSystemEntityType pcm = FileSystemEntity.typeSync(pkgConfigMap);
    if (pkgConfigMap == FileSystemEntityType.notFound) {
      _log.severe("ERROR: $pkgConfigMap does not refer to a .packages file.");
      exit(0);
    } else {
      // _log.info("Found .packages file for $pkg at $pkgConfigMap");
    }

  // 2. get templates for the pkg
  if ((template == null) || _externalTemplates.containsKey(template)) {
    // String templateDir = _externalTemplates[template];
    // _log.finer("found template $template in pkg $pkg: $templateDir");

    String mainScriptPath = _externalPkgPath + "/lib/dartrix.dart";
    // e.g. /Users/gar/mobileink/hello_template/lib/dartrix.dart
    // _log.finer("mainScriptPath: $mainScriptPath");

    // Verify: main script (dartrix.dart) exists.
    // FileSystemEntityType newCmdEntity = FileSystemEntity.typeSync(mainScriptPath);
    // if (newCmdEntity == FileSystemEntityType.notFound) {
    //   _log.severe("ERROR: $pkg is not a Dartrix template pkg (lib/dartrix.dart not found)");
    //   exit(0);
    // }
    if ( !verifyExists(mainScriptPath) ) exit(0);

    // Run the external pkg in an Isolate.

    // WARNING: if 1) the pkg is listed as a dep in pubspec.yaml, and 2) the
    // user passes it with path: anyway, and 3) the command is 'pub run' and
    // not 'pub global run', then spawning will print a warning:
    // "Warning: Interpreting this as package URI, 'package:hello_template/dartrix.dart'"
    // This also happens if running with no pubspec.yaml.

    // The fix: use a package: URI. This works as long as you also pass the
    // packageConfigMap file ref.

    // WARNING 2: Running without a pubspec.yaml file works with pub global,
    // but pub run complains about a missing pubspec.yaml file. Evidently
    // they use different strategies to resolve deps.  The latter is only
    // for running within a package directory.

    // Uri mainScriptUri = Uri.parse("file://" + mainScriptPath);

    Uri packageUri = Uri.parse("package:" + path.basenameWithoutExtension(_externalPkgPath) + "/dartrix.dart");

    final rPort = ReceivePort();
    rPort.listen(_generateFromPath, onDone: _externalOnDone);

    final stopPort = ReceivePort();

    if (options['help']) {
      if (args == null) {
        args = ["--help"];
      } else {
        args.add("--help");
      }
    }

    if (debug.verbose) _log.info("${infoPen('Spawning')} $packageUri with args $args");
    Isolate externIso = await Isolate.spawnUri(
      packageUri,
      // Uri.parse("package:hello_template/dartrix.dart"),
      // Uri.parse(mainScriptPath),
      [template, ...?args],
      rPort.sendPort,
      packageConfig: Uri.parse(pkgConfigMap),
      // automaticPackageResolution: true,
      // onError: errorPort.sendPort,
      onExit: stopPort.sendPort,
      debugName: template
    );

    await stopPort.first; // Do not exit until externIso exits:
    // _log.info("closing ports");
    rPort.close();
    stopPort.close();

  } else {
    _log.info("Template ${warningPen('$template')} not found in Dartrix lib ${warningPen('$pkg')}; canceling.");
  }
}

/// This routine is invoke when the external isolate returns data.
void _generateFromPackage(dynamic _xData) {
  _log.finer("_generateFromPackage: $_xData");
}

void spawnExternalFromPackage(String pkg, String template, List<String> args) async {
  _log.info("entry: spawnExternalFromPackage($pkg, $template, $args)");

  String pkgName;
  String pkgPackageUriStr;
  if (pkg.startsWith("package:")) {
    pkgName = pkg.replaceAll(RegExp("^package:"), '');
    pkgPackageUriStr = pkg;
  }
  if (pkg.startsWith("pkg:")) {
    pkgName = pkg.replaceAll(RegExp("^pkg:"), '');
    pkgPackageUriStr = "package:" + pkgName;
  }

  // We're going to spawn the package, but before we do, we read its template
  // library.  To do either we need to read its "package config" file, which
  // is in 'package:pkg_name/.dart/.dart_tool/package_config.json.'
  // To find this file, we go through the user's "dart config", which is in
  // $HOME/.dart.d.  That dir contains the pubspec.yaml file where the user
  // lists all the deps he/she might want to use across projects;
  // in particular, it lists the Dartrix app and any external (3rd-party)
  // Dartrix template packages the user has installed.
  // So our first step is to obtain the package_config.json file from the
  // user's dart config dir, and from it obtain the location of the
  // desired template package. From there we can 1) read the templates in
  // the package, and 2) spawn the package itself
  // (i.e. package:pkg_name/dartrix.dart).

  // Step 1: get user's dart config (a packageConfig2)
  PackageConfig userPackageConfig2 = await getUserPackageConfig2();
  _log.info("got userPackageConfig2");
  // var packageUri = Uri.parse(pkgPackageUriStr + "/");
  // // 'resolve' gives "file:///.../lib"
  // var packageUriFile = userPackageConfig2.resolve(packageUri);
  // _log.info("resolve(packageUri): ${packageUriFile}");

  // Step 2. target pkg is listed as a dep in the packageConfig2;
  // find it
  Package pkgPackageConfig2 = userPackageConfig2.packages.firstWhere(
    (pkg) => pkg.name == pkgName,
    orElse: () {
      _log.severe("Package $pkgName is not configured. To install, add it as a package or path dependency in \$HOME/.dart.d/pubspec.yaml and run 'pub get' from that directory.");
      exit(0);
    }
  );
  _log.info("pkgPackageConfig2: $pkgPackageConfig2");

  // Step 3.  Get the (file) root of the package. We need this to
  // a) read the templates, and b) spawn the package.
  var pkgRootUri = pkgPackageConfig2.root;
  _log.info("pkgPackageConfig2.root: ${pkgRootUri}");

  // Step 4.  Before spawning the package, get the templates.
  initXTemplates(pkgRootUri.path);

  // Step 5. Construct the packageConfig Uri required by spawnUri.
  // WARNING: spawnUri evidently does not yet support version 2, so
  // construct a version 1 packageConfig (i.e. using a .packages file)
  var pkgPackageConfig1Uri = Uri.parse(pkgRootUri.path + "/.packages");

  // Version 2 will use /.dart_tools/package_config.json

  final rPort = ReceivePort();
  rPort.listen(_generateFromPath, onDone: _externalOnDone);
  final stopPort = ReceivePort();

  if (debug.verbose) {
    _log.info("${infoPen('Spawning')} $pkgPackageUriStr with args $args");
  }
  try {
    Isolate externIso = await Isolate.spawnUri(
      // To avoid annoying warning, always use a package: Uri, not a file: Uri
      Uri.parse(pkgPackageUriStr + "/dartrix.dart"),
      [template, ...?args],
      rPort.sendPort,
      // WARNING: packageConfig evidently does not support v2
      packageConfig: pkgPackageConfig1Uri,
      // onError: errorPort.sendPort,
      onExit: stopPort.sendPort,
      debugName: template
    );
  } catch (e) {
    _log.shout(e);
    //FIXME: this assumes that e is IsolateSpawnException
    _log.info("Remedy: add the package to \$HOME/.dart.d/pubspec.yaml, then run '\$ pub get' from that directory.");
    _log.info("Make sure the package is a Dartrix library (contains 'lib/dartrix.dart'). ");
    exit(0);
  }

  await stopPort.first; // Do not exit until externIso exits:
  // _log.info("closing ports");
  rPort.close();
  stopPort.close();
}

void _externalOnDone() {
  // _log.finer("_externalOnDone");
}

// void _onStopData(dynamic data) {
//   _log.finer("_onStopData: $data");
// }

// void _onStopDone() {
//   _log.finer("_onStopDone");
// }

void generateFromPlugin(String pkg, String template, List<String> args) {
  // _log.finer("generateFromPlugin: $pkg, $template, args: $args");
  if (pkg.startsWith("path:")) {
    spawnExternalFromPath(pkg, template, args);
  } else {
    if (pkg.startsWith("package:")) {
      spawnExternalFromPackage(pkg, template, args);
    } else {
      if (pkg.startsWith("pkg:")) {
        spawnExternalFromPackage(pkg, template, args);
      } else {
        throw ArgumentError("-x $pkg: must start with path: or package: or pkg:");
      }
    }
  }
}

void generateFromExternal(String template, Map data) {
  _log.info("generateFromExternal: $template, $data");
}
