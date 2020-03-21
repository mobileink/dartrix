import 'dart:io';
import 'dart:isolate';
import 'package:package_config/package_config.dart';

import 'package:dartrix/src/resolver.dart';

typedef void onData(dynamic msg);
typedef void onDone();

void spawnPluginFromPackage(
  // String main,
  onData dataCallback, onDone onDoneCallback,
  String _pkg, // _pkg uri may be :path, :package, or :pkg
  List<String> args)
async {
  print("entry: spawnPluginFromPackage($_pkg, $args)");

  // map keys: name, uri, or path
  Map pkg = resolvePkgRef(_pkg);
  print("resolved $_pkg to $pkg");

  // to spawn, we need:
  // 1. the pkg uri in package:foo form, as first arg to spawnUri
  // 2.  the packageConfig file uri, as name packageConfig: arg.

  // If the pkg is listed as a dep in the local pubspec.yaml,
  // then the pkg uri would suffice; the runtime would be able to
  // look up the file location from ./.packages.  But since plugins
  // may not be listed as local deps, we must always find the file
  // uri ourselves, and supply it as the optional 'packageConfig' arg.

  // So for package: uris, we have the pkgUri and need to follow the config
  // files to get the path to the .packages file.

  // For path: uris, we already have the file path to the pkg root dir,
  // from which we can construct both the package: uri and the path
  // to the .packages file.

  // If we have a package: uri:
  // Step 1: get user's dart config (a packageConfig2)
  PackageConfig userPackageConfig2 = await getUserPackageConfig2();
  print("got userPackageConfig2");
  // var packageUri = Uri.parse(pkg['uri'] + "/");
  // // 'resolve' gives "file:///.../lib"
  // var packageUriFile = userPackageConfig2.resolve(packageUri);
  // print("resolve(packageUri): ${packageUriFile}");

  // Step 2. target pkg is listed as a dep in the packageConfig2;
  // find it
  Package pkgPackageConfig2 = userPackageConfig2.packages.firstWhere(
    (_pkg) => _pkg.name == pkg['fullName'],
    orElse: () {
      print("Package ${pkg['fullName']} is not configured. To install, add it as a package or path dependency in \$HOME/.dart.d/pubspec.yaml and run 'pub get' from that directory.");
      exit(0);
    }
  );
  print("pkgPackageConfig2: $pkgPackageConfig2");

  // Step 3.  Get the (file) root of the package. We need this to
  // a) read the templates, and b) spawn the package.
  var pkgRootUri = pkgPackageConfig2.root;
  print("pkgPackageConfig2.root: ${pkgRootUri}");

  // Step 5. Construct the packageConfig Uri required by spawnUri.
  // WARNING: spawnUri evidently does not yet support version 2, so
  // construct a version 1 packageConfig (i.e. using a .packages file)
  var pkgPackageConfig1Uri = Uri.parse(pkgRootUri.path + "/.packages");

  // Version 2 will use /.dart_tools/package_config.json

  final dataPort = ReceivePort();

  dataPort.listen(dataCallback, onDone: onDoneCallback);
  final stopPort = ReceivePort();

  // if (config.verbose) {
    print("Spawning ${pkg['uri']} with args $args");
  // }
  var spawnUri = Uri.parse(pkg['uri'] + "/" + pkg['name'] + "_dartrix.dart");
  print("spawning Uri: $spawnUri");
  print("config Uri: $pkgPackageConfig1Uri");
  try {
    Isolate externIso = await Isolate.spawnUri(
      // To avoid annoying warning, always use a package: Uri, not a file: Uri
      // Uri.parse(pkg['uri'] + "/" + pkg['name'] + "_dartrix.dart"),
      spawnUri,
      args, // [template, ...?args],
      dataPort.sendPort,
      // WARNING: packageConfig evidently does not support v2
      packageConfig: pkgPackageConfig1Uri,
      // onError: errorPort.sendPort,
      onExit: stopPort.sendPort,
      // debugName: template
    );
  } catch (e) {
    print(e);
    //FIXME: this assumes that e is IsolateSpawnException
    print("Remedy: add the package to \$HOME/.dart.d/pubspec.yaml, then run '\$ pub get' from that directory.");
    print("Make sure the package is a Dartrix library (contains 'lib/dartrix.dart'). ");
    exit(0);
  }
  await stopPort.first; // Do not exit until externIso exits:
  dataPort.close();
  stopPort.close();
}

