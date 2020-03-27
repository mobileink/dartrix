import 'dart:io';
import 'dart:isolate';
// import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
// import 'package:dartrix/src/resolver.dart';

typedef onData = void Function(dynamic msg);
typedef onDone = void Function();

void spawnPluginFromPackage(
    // String main,
    onData dataCallback,
    onDone onDoneCallback,
    String libName, // pkg name without _dartrix
    List<String> args) async {
  // Config.ppLogger.v('entry: spawnPluginFromPackage($libName, $args)');

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
  // var pkgConfigUriPath = path.normalize(pkgRootUri.path); // + '/.packages');
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
    Config.ppLogger.v('spawnUri: $spawnUri'); //\nconfigUri: $pkgPackageConfig1Uri');
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
