/// sanity checker for template development. Checks that each template has a
/// docstring, manpage, handler, etc. Checks for bad chars (e.g. '-') in
/// paths. Etc.
import 'dart:async';
import 'dart:core';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/which.dart';
import 'package:strings/strings.dart';
// import 'package:resource/resource.dart';
// import 'package:package_resolver/package_resolver.dart';

// import 'package:pub_cache/pub_cache.dart';

import 'package:mustache_template/mustache_template.dart';

bool verbose = false;

void main(List<String> args) {
  var parser = ArgParser();
  // parser.addOption('template', abbr: 't',
  //   valueHelp: "[a-z_][a-z0-9_]*",
  //   help: "Template name.",
  //   defaultsTo: 'plugin',
  //   // callback: (t) => validateTemplateName(t)
  // );
  parser.addFlag('help', abbr: 'h', defaultsTo: false);
  parser.addFlag('verbose', abbr: 'v', defaultsTo: false);

  var options = parser.parse(args);

  verbose = options['verbose'];

  // var root = path.dirname(Platform.script.toString());
  // print("proj root: $root");

  if (options['help']) {
    print(parser.usage);
    exit(0);
  }

  // FIXME: read the templates to generate the list
  print("Built-in templates:");
  print("    plugin (default)");
  print("    split-plugin");
  print("    app");
}
