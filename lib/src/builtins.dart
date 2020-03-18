import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

var _log = Logger('builtin');

//FIXME: use PathSet?
Set<String> builtinTemplates;

void initBuiltinTemplates() {
  _log.info("builtin.initBuiltinTemplates");

  String scriptPath = path.prettyUri(Platform.script.toString());
  // print("scriptPath: ${scriptPath}");

  String templatesRoot = path.dirname(scriptPath) + "/../templates";
  templatesRoot = path.canonicalize(templatesRoot);

  List builtins = Directory(templatesRoot).listSync();
  builtins.retainWhere((f) => f is Directory);
  // print("getBuiltinTemplates: $builtins");
  builtinTemplates = builtins.map<String>((d) {
      return path.basename(d.path);
  }).toSet();
}
