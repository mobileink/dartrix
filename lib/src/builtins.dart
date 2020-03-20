import 'dart:io';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;

var _log = Logger('builtin');

/// Initialize builtinTemplates variable (Set).
///
/// Read the <root>/lib/templates directory, retaining only directory entries. Each
/// subdirectory represents one template.
void initBuiltinTemplates() async {
  _log.info("builtins.initBuiltinTemplates");

  // Procedure: get path to pkg root, then templates subdir, then read the
  // latter and filter.

  // Isolate.packageConfig gives abs. file uri;
  // Platform.script gives relative path
  // Alternative: Package.root?
  // Uri packageConfigUri = await Isolate.packageConfig;
  // // e.g. file:///Users/gar/mobileink/dartrix/.packages
  // _log.info("packageConfigUri $packageConfigUri");

  String scriptPath = path.prettyUri(Platform.script.toString());
  // e.g. ../../mobileink/dartrix/bin/new.dart
  _log.info("scriptPath: ${scriptPath}");

  String templatesRoot = path.dirname(scriptPath) + "/../lib/templates";
  templatesRoot = path.canonicalize(templatesRoot);

  List builtins = Directory(templatesRoot).listSync();
  builtins.retainWhere((f) => f is Directory);
  // print("getBuiltinTemplates: $builtins");
  //builtinTemplates =
  // builtins.map<String,String>((d) {
  builtins.forEach((builtin) {
      String basename = path.basename(builtin.path);
      String docstring;
      try {
        docstring = File(builtin.path + ".docstring")
        .readAsStringSync();
      } on FileSystemException {
        // if (debug.debug)
        // _log.info("docstring not found for ${builtin.path}");
      }
      builtinTemplates[basename] = docstring ?? "";
  });
  if (debug.debug) debug.debugListBuiltins();
}
