import 'dart:io';
import 'dart:isolate';

import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/paths.dart';

typedef onData = void Function(dynamic msg);
typedef onDone = void Function();

void spawnPluginFromPackage(
    // String main,
    onData dataCallback,
    onDone onDoneCallback,
    String libName, // pkg name without _dartrix
    List<String> args) async {
  Config.debugLogger.d('entry: spawnPluginFromPackage($libName, $args)');

  // var pkgRootPath = await resolvePkgRoot(libName);

  ////////////////////////////////////////////////////////////////

  // var userPackageConfig2 = await getUserPackageConfig2();
  // // Step 2. target pkg is listed as a dep in the packageConfig2; find it
  // // Package
  // var pkgName = libName + '_dartrix';
  // var pkgRoot;
  // var pkgPackageConfig2;
  // try {
  //   pkgPackageConfig2 = userPackageConfig2.packages
  //   .firstWhere((_pkg) {
  //       return _pkg.name == pkgName; // ['fullName'],
  //   });
  // } catch(e) {
  //   Config.ppLogger.e('Dartrix lib pkg $pkgName not found');
  //   Config.ppLogger.e(e);
  //   pkgRoot = await fetchPackage(pkgName);
  //   Config.ppLogger.v('found hosted: $pkgRoot');
  // }
  // //         'Package ${pkgName} is not configured. To install, add it as a package or path dependency in \$HOME/.dart.d/pubspec.yaml and run "pub get" from that directory.');

  // Config.ppLogger.v('pkgPackageConfig2: $pkgPackageConfig2');
  // Config.ppLogger.v('pkgRoot: $pkgRoot');

  // // Step 3.  Get the (file) root of the package. We need this to
  // // a) read the templates, and b) spawn the package.
  // var pkgRootUri = (pkgPackageConfig2 != null)
  // ? pkgPackageConfig2.root
  // : Uri.parse(pkgRoot + '/');

  // if (Config.debug) {
  //   Config.ppLogger
  //       .v('pkg uri:  ${pkgPackageConfig2?.name}\npkg root: ${pkgRootUri}');
  // }

////////////////////////////////////////////////////////////////

  // Step 5. Construct the packageConfig Uri required by spawnUri.
  // WARNING: spawnUri evidently does not yet support version 2, so
  // construct a version 1 packageConfig (i.e. using a .packages file)
  // var pkgConfigUriPath = path.canonicalize(pkgRootUri.path); // + '/.packages');
  // var pkgPackageConfig1Uri = Uri.parse(pkgConfigUriPath);

  // Version 2 will use /.dart_tools/package_config.json

  final dataPort = ReceivePort();

  dataPort.listen(dataCallback, onDone: onDoneCallback);
  final stopPort = ReceivePort();

  // if (config.verbose) {
  // print('Spawning package:${pkgName}_dartrix with args $args');
  // }
  // var pkgUri = 'package:${pkgName}_dartrix';
  // var spawnUri = Uri.parse(pkgUri + '/' + pkgName + '_dartrix.dart');
  var spawnUri =
      // Uri.parse(pkgRootUri.path + 'lib/' + pkgName + '_dartrix.dart');
      // Uri.parse(pkgRootPath + 'lib/' + libName + '_dartrix.dart');
      Uri.parse(Config.libPkgRoot + 'lib/' + libName + '_dartrix.dart');
  if (Config.debug) {
    Config.ppLogger
        .v('spawnUri: $spawnUri'); //\nconfigUri: $pkgPackageConfig1Uri');
  }
  try {
    // Isolate externIso =
    await Isolate.spawnUri(
      // Use a file:// URI, together with automaticPackageResolution: true.
      // This works when there is no .packages file, as in the case of hosted
      // packages in .pub-cache.
      spawnUri,
      args, // [template, ...?args],
      dataPort.sendPort,
      // packageConfig: pkgPackageConfig1Uri, // breaks if pkg is in pub-cache
      automaticPackageResolution: true,
      // onError: errorPort.sendPort,
      onExit: stopPort.sendPort,
      // debugName: template
    );
    if (Config.debug) {
      Config.ppLogger.v('spawned Uri: $spawnUri');
    }
  } catch (e) {
    print(e);
    //FIXME: this assumes that e is IsolateSpawnException
    print(
        'Remedy: add the package to \$HOME/.dart.d/pubspec.yaml, then run "\$ pub get" from that directory.');
    print(
        'Make sure the package is a Dartrix library (contains "lib/dartrix.dart"). ');
    exit(0);
  }
  await stopPort.first; // Do not exit until externIso exits:
  dataPort.close();
  stopPort.close();
}

/// This routine is invoked when the external isolate returns data.
void spawnCallback(dynamic _xData) {
  // Config.debugLogger.d('spawnCallback: $_xData');
  // Config.logger.d('_externalPkgPath path: $_externalPkgPath');
  // Config.logger.d('Config.templateRoot: ${Config.templateRoot}');
  // Config.logger.d('_externalTemplates: $_externalTemplates');

  xData = _xData;
  // step one: merge data maps
  if (xData.isNotEmpty) {
    if (_xData['dartrix']['mergeData']) {
      mergeExternalData(tData, _xData);
      // if (tData['class'] != Config.argParser.getDefault('class')) {}
    }
  }
  // mergeUserOptions();

  if (debug.debug) debug.debugData(null);
  // if (debug.debug) debug.debugPathRewriting(_xData);

  // get out path
  // var outPathPrefix = tData['outpath'];
  // Config.logger.v('outPathPrefix: $outPathPrefix');

  // iterate over template fileset
  // var t = tData['template'];
  // var _templateRoot = _templatesRoot + _externalTemplates[tData['template']];
  // Config.logger.d('_templateRoot: $_templateRoot');
  List tFileList = Directory(Config.templateRoot).listSync(recursive: true);
  tFileList.removeWhere((f) => f.path.endsWith('~'));
  // tFileList.removeWhere((f) => f.path.endsWith('dartrix.yaml'));
  tFileList.removeWhere((f) => f.path.contains('/.'));
  // tFileList.removeWhere((f) => f.path.endsWith('/.yaml'));
  tFileList.retainWhere((f) => f is File);

  if (Config.verbose) {
    Config.ppLogger.v(
        'Generating files from templates and copying assets from ${Config.templateRoot}');
  }

  var writtenFiles = [];

  tFileList.forEach((tfile) {
    // Config.ppLogger.d('tfile: $tfile');
    var outSubpath = path.canonicalize(// outPathPrefix +
        tfile.path.replaceFirst(Config.templateRoot, ''));
    outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');
    if (Config.debug) {
      Config.ppLogger.d('outSubpath: $outSubpath');
    }
    outSubpath = path.canonicalize(rewritePath(outSubpath));
    if (Config.debug) {
      Config.ppLogger.d('outSubpath rewritten: $outSubpath');
    }

    // exists?
    if (!tData['dartrix']['force']) {
      var exists = FileSystemEntity.typeSync(outSubpath);
      if (exists != FileSystemEntityType.notFound) {
        Config.ppLogger.e(
            'ERROR: $outSubpath already exists; cancelling. Use -f to force overwrite.');
        exit(0);
      }
    }
    var dirname = path.dirname(outSubpath);
    // Config.logger.d('dirname: $dirname');
    if (!Config.dryRun) {
      Directory(dirname).createSync(recursive: true);
    }

    if (tfile.path.endsWith('mustache')) {
      var contents;
      contents = tfile.readAsStringSync();
      var template =
          Template(contents, name: outSubpath, htmlEscapeValues: false);
      var newContents;
      try {
        newContents = template.renderString(tData);
      } catch (e) {
        Config.ppLogger.e('Template processing error: $e');
        exit(0);
      }
      // Config.logger.d(newContents);
      if (Config.verbose) {
        Config.ppLogger.v('   ' + tfile.path + '\n=> $outSubpath');
      }
      if (!Config.dryRun) {
        File(outSubpath).writeAsStringSync(newContents);
        writtenFiles.add(outSubpath);
      }
    } else {
      if (Config.verbose) {
        // Config.ppLogger.v('=> $outSubpath');
        Config.ppLogger.v('   ' + tfile.path + '\n=> $outSubpath');
      }
      if (!Config.dryRun) {
        tfile.copySync(outSubpath);
        writtenFiles.add(outSubpath);
      }
    }
  });
  var action;
  if (Config.dryRun) {
    action = 'would generate';
  } else {
    action = 'generated';
  }

  if (writtenFiles.isNotEmpty) {
    //List<String>
    var ofs = [
      for (var f in writtenFiles) path.dirname(f),
    ];
    ofs.sort((a, b) => a.length.compareTo(b.length));
    // print('ofx ${ofs.first}');
    var template = path.basename(Config.templateRoot);
    Config.ppLogger.i(
        'Template ${template} ${action} ${tFileList.length} files to ${ofs.first}.');
  }
}
