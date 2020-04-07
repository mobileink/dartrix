// import 'dart:io';
// import 'dart:isolate';

// import 'package:args/args.dart';
// import 'package:mustache_template/mustache_template.dart';
// import 'package:package_config/package_config.dart';
// import 'package:path/path.dart' as path;
// import 'package:sprintf/sprintf.dart';

// import 'package:dartrix/src/config.dart';
// import 'package:dartrix/src/data.dart';
// import 'package:dartrix/src/debug.dart' as debug;
// import 'package:dartrix/src/dispatcher.dart';
// import 'package:dartrix/src/paths.dart';
// import 'package:dartrix/src/resolver.dart';
// import 'package:dartrix/src/utils.dart';

/// Initialize builtinTemplates variable (Set).
///
/// Read the <root>/templates directory, retaining only directory entries. Each
/// subdirectory represents one template.
// void initBuiltinTemplates() async {
//   // Config.logger.i('builtins.initBuiltinTemplates');

//   //String
//   var templatesRoot = await resolveBuiltinTemplatesRoot();

//   //List
//   var builtins = Directory(templatesRoot).listSync();
//   builtins.retainWhere((f) => f is Directory);
//   // print('getBuiltinTemplates: $builtins');
//   //builtinTemplates =
//   // builtins.map<String,String>((d) {
//   builtins.forEach((builtin) {
//     // String
//     var basename = path.basename(builtin.path);
//     // String
//     var docstring;
//     try {
//       docstring = File(builtin.path + '.docstring').readAsStringSync();
//     } on FileSystemException {
//       // if (debug.debug)
//       // Config.logger.i('docstring not found for ${builtin.path}');
//     }
//     builtinTemplates[basename] = docstring ?? '';
//   });
//   if (debug.debug) debug.debugListBuiltins();
// }

void printDartrixUsage() {
  print(
      'Dartrix template library. A collection of general templates for softwared development.  Mainly but not exclusively Dart and Flutter code.');
}
