// import 'dart:async';
import 'dart:io';
import 'dart:isolate';

// import 'package:args/args.dart';
// import 'package:logger/logger.dart';
import 'package:mustache_template/mustache_template.dart';
// import 'package:package_config/package_config.dart';
// import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
// import 'package:dartrix/src/utils.dart';

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
String _externalPkgPath;
String _templatesRoot;

Map<String, String> _externalTemplates;

void initPluginTemplates(String pkgRef) async {
  // Config.logger.i("initPluginTemplates $pkgRef");
  Map pkg = resolvePkgRef(pkgRef);

  if (pkg['path'] != null) {
    _externalPkgPath = path.canonicalize(pkgRef);
    // Config.logger.d('_externalPkgPath path: $_externalPkgPath');
  } else {
    _externalPkgPath = await resolvePkgRoot(pkgRef);
  }
  //String
  var templatesRoot = _externalPkgPath + '/templates';
  _templatesRoot = path.canonicalize(templatesRoot);

  List externals = Directory(_templatesRoot).listSync();
  externals.retainWhere((f) => f is Directory);
  // Config.logger.d('getExternalTemplates: $externals');
  // _externalTemplates = Map.fromIterable(
  //   externals,
  //   key: (dir) => path.basename(dir.path),
  //   value: (dir) => dir.path.replaceFirst(_templatesRoot, '')
  // );
  _externalTemplates = {
    for (var dir in externals)
      path.basename(dir.path): dir.path.replaceFirst(_templatesRoot, ''),
  };
}

/// This routine is invoke when the external isolate returns data.
void spawnCallback(dynamic _xData) {
  Config.logger.d('spawnCallback: $_xData');
  // Config.logger.d('_externalPkgPath path: $_externalPkgPath');
  // Config.logger.d('_templatesRoot path: $_templatesRoot');
  // Config.logger.d('_externalTemplates: $_externalTemplates');

  xData = _xData;
  // step one: merge data maps
  if (_xData['dartrix']['mergeData']) {
    mergeExternalData(tData, _xData);
    if (tData['class'] != Config.argParser.getDefault('class')) {}
  }
  mergeUserOptions();

  if (debug.debug) debug.debugData(null);

  if (debug.debug) debug.debugPathRewriting(_xData);
  // get out path
  var outPathPrefix = tData['outpath'];

  // iterate over template fileset
  // var t = tData['template'];
  var _templateRoot = _templatesRoot + _externalTemplates[tData['template']];
  // Config.logger.d('_templateRoot: $_templateRoot');
  List tFileset = Directory(_templateRoot).listSync(recursive: true);
  tFileset.removeWhere((f) => f.path.endsWith('~'));
  tFileset.retainWhere((f) => f is File);

  if (Config.verbose) {
    Config.logger.d(
        'Generating files from templates and copying assets (cwd: ${Directory.current.path}):');
  }
  tFileset.forEach((tfile) {
    // Config.logger.d('tfile: $tfile');
    var outSubpath = path
        .normalize(outPathPrefix + tfile.path.replaceFirst(_templatesRoot, ''));
    outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');
    // Config.logger.d('outSubpath: $outSubpath');
    outSubpath = path.normalize(rewritePath(outSubpath));

    // exists?
    if (!tData['dartrix']['force']) {
      var exists = FileSystemEntity.typeSync(outSubpath);
      if (exists != FileSystemEntityType.notFound) {
        Config.logger.e(
            'ERROR: $outSubpath already exists; cancelling. Use -f to force overwrite.');
        exit(0);
      }
    }
    var dirname = path.dirname(outSubpath);
    // Config.logger.d('dirname: $dirname');
    Directory(dirname).createSync(recursive: true);

    if (Config.verbose) Config.logger.d('   ' + tfile.path);
    if (tfile.path.endsWith('mustache')) {
      var contents;
      contents = tfile.readAsStringSync();
      var template =
          Template(contents, name: outSubpath, htmlEscapeValues: false);
      var newContents = template.renderString(tData);
      // Config.logger.d(newContents);
      if (Config.verbose)
        Config.logger.d('=> ${Directory.current.path}/$outSubpath');
      File(outSubpath).writeAsStringSync(newContents);
    } else {
      if (Config.verbose)
        Config.logger.d('=> ${Directory.current.path}/$outSubpath');
      tfile.copySync(outSubpath);
    }
  });
}

void spawnExternalFromPath(
    String pkg, String template, List<String> args) async {
  // Config.logger.d('spawnExternalFromPath: $pkg');

  // 1. this constructs the file:// url for the pkg as _externalPkgPath
  // and a list of its template roots in _exterternalTemplates.
  //String
  var packagePath = pkg.replaceFirst('path:', '');
  initPluginTemplates(packagePath);

  // 2. get the .packages file for the pkg. we need this because the pkg may
  // have deps that dartrix does not have.  It will be passed as the
  // packageConfig parm to spawnUri.
  var pkgConfigMap = _externalPkgPath + '/.packages';
  // verify:
  //FileSystemEntityType
  var pcm = FileSystemEntity.typeSync(pkgConfigMap);
  if (pcm == FileSystemEntityType.notFound) {
    Config.logger.e('ERROR: $pcm does not refer to a .packages file.');
    exit(0);
  } else {
    // Config.logger.i('Found .packages file for $pkg at $pkgConfigMap');
  }

  // 2. get templates for the pkg
  if ((template == null) || _externalTemplates.containsKey(template)) {
    // String templateDir = _externalTemplates[template];
    // Config.logger.d('found template $template in pkg $pkg: $templateDir');

    //String
    var mainScriptPath = _externalPkgPath + '/lib/dartrix.dart';
    // e.g. /Users/gar/mobileink/hello_template/lib/dartrix.dart
    // Config.logger.d('mainScriptPath: $mainScriptPath');

    // Verify: main script (dartrix.dart) exists.
    // FileSystemEntityType newCmdEntity = FileSystemEntity.typeSync(mainScriptPath);
    // if (newCmdEntity == FileSystemEntityType.notFound) {
    //   Config.logger.e('ERROR: $pkg is not a Dartrix template pkg (lib/dartrix.dart not found)');
    //   exit(0);
    // }
    if (!verifyExists(mainScriptPath)) exit(0);

    // Run the external pkg in an Isolate.

    // WARNING: if 1) the pkg is listed as a dep in pubspec.yaml, and 2) the
    // user passes it with path: anyway, and 3) the command is 'pub run' and
    // not 'pub global run', then spawning will print a warning:
    // 'Warning: Interpreting this as package URI, 'package:hello_template/dartrix.dart''
    // This also happens if running with no pubspec.yaml.

    // The fix: use a package: URI. This works as long as you also pass the
    // packageConfigMap file ref.

    // WARNING 2: Running without a pubspec.yaml file works with pub global,
    // but pub run complains about a missing pubspec.yaml file. Evidently
    // they use different strategies to resolve deps.  The latter is only
    // for running within a package directory.

    // Uri mainScriptUri = Uri.parse('file://' + mainScriptPath);

    //Uri
    var packageUri = Uri.parse('package:' +
        path.basenameWithoutExtension(_externalPkgPath) +
        '/dartrix.dart');

    final rPort = ReceivePort();
    rPort.listen(spawnCallback, onDone: externalOnDone);

    final stopPort = ReceivePort();

    if (Config.options['help']) {
      if (args == null) {
        args = ['--help'];
      } else {
        args.add('--help');
      }
    }

    if (Config.verbose) {
      Config.logger.i('${infoPen("Spawning")} $packageUri with args $args');
    }
    // Isolate externIso =
    await Isolate.spawnUri(
        packageUri,
        // Uri.parse('package:hello_template/dartrix.dart'),
        // Uri.parse(mainScriptPath),
        [template, ...?args],
        rPort.sendPort,
        packageConfig: Uri.parse(pkgConfigMap),
        // automaticPackageResolution: true,
        // onError: errorPort.sendPort,
        onExit: stopPort.sendPort,
        debugName: template);

    await stopPort.first; // Do not exit until externIso exits:
    // Config.logger.i('closing ports');
    rPort.close();
    stopPort.close();
  } else {
    Config.logger.i(
        'Template ${warningPen("$template")} not found in Dartrix lib ${warningPen('$pkg')}; canceling.');
  }
}

/// This routine is invoke when the external isolate returns data.
void generateFromPackage(dynamic _xData) {
  Config.logger.d('generateFromPackage: $_xData');
}

void externalOnDone() {
  // Config.logger.d('externalOnDone');
}

// void _onStopData(dynamic data) {
//   Config.logger.d('_onStopData: $data');
// }

// void _onStopDone() {
//   Config.logger.d('_onStopDone');
// }

void generateFromPlugin(String pkg, String template, List<String> args) async {
  Config.logger.d('generateFromPlugin: $pkg, $template, args: $args');
  if (pkg.startsWith('path:')) {
    spawnExternalFromPath(pkg, template, args);
  } else {
    // Before spawning the package, get the templates.
    if (pkg.startsWith('package:') || pkg.startsWith('pkg:')) {
      // initPluginTemplates(pkg);
      await spawnPluginFromPackage(
          spawnCallback, externalOnDone, pkg, [template, ...?args]);
      // template, args);
    } else {
      throw ArgumentError('-x $pkg: must start with path: or package: or pkg:');
    }
  }
}

// void generateFromExternal(String template, Map data) {
//   Config.logger.i('generateFromExternal: $template, $data');
// }
