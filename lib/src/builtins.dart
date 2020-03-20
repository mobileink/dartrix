import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;

var _log = Logger('builtin');

/// Initialize builtinTemplates variable (Set).
///
/// Read the <root>/templates directory, retaining only directory entries. Each
/// subdirectory represents one template.
void initBuiltinTemplates() {
  // _log.info("builtin.initBuiltinTemplates");

  String scriptPath = path.prettyUri(Platform.script.toString());
  // print("scriptPath: ${scriptPath}");

  String templatesRoot = path.dirname(scriptPath) + "/../templates";
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
