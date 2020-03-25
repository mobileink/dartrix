import 'dart:io';
// import 'dart:isolate';

import 'package:args/args.dart';
import 'package:mustache_template/mustache_template.dart';
// import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
import 'package:sprintf/sprintf.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/handlers/dart_cmdsuite.dart';
import 'package:dartrix/src/handlers/bashrc.dart';
import 'package:dartrix/src/paths.dart';
import 'package:dartrix/src/resolver.dart';

void printBuiltins() async {
  // ArgResults options)
  // print('builtins.printBuiltins'); // ${options.arguments}');
  //Uri
  // var packageConfigUri = await Isolate.packageConfig;
  // // e.g. file:///Users/gar/mobileink/dartrix/.packages
  // if (Config.debug) {
  //   Config.logger.i('packageConfigUri $packageConfigUri');
  // }

  // WARNING: for pub global activateds, the current dir of the script contains
  // .packages, which is the value of Isolate.packageConfig, but it does NOT
  // contain all of the subdirs of the original pkg root. It only the bin dir,
  // plus the pub stuff (.dart_tool, .packages, pubspec.lock).

  // e.g.
  // $ l ~/.pub-cache/global_packages/stagehand/
  // total 8.0K
  // drwxr-xr-x 3 gar staff  102 Mar 10 18:40 .dart_tool/
  // -rw-r--r-- 1 gar staff 2.9K Mar 10 18:40 .dart_tool/package_config.json
  // -rw-r--r-- 1 gar staff 1.3K Mar 10 18:40 .packages
  // drwxr-xr-x 3 gar staff  102 Mar 10 18:40 bin/
  // -rw-r--r-- 1 gar staff 1.3M Mar 10 18:40 bin/stagehand.dart.snapshot.dart2
  // -rw-r--r-- 1 gar staff 2.4K Mar 10 18:40 pubspec.lock

  // So to find the templates/ dir, we have to look it up in the .packages file
  // using findPackageConfigUri.  this is a v1 pkg config, i.e. a .packages
  // file, so back up one segment: String libDir =
  // path.dirname(packageConfigUri.path); var templatesRoot =
  // path.dirname(packageConfigUri.path) + '/templates'; List

  // FIXME: use listBuiltinTemplates
  var templatesRoot = await resolveBuiltinTemplatesRoot();
  var templates = Directory(templatesRoot).listSync()
    ..retainWhere((f) => f is Directory);

  print('Builtin templates:');
  templates.forEach((t) {
    var tName = path.basename(t.path);
    //String
    var docString;
    try {
      docString =
          File(templatesRoot + '/' + tName + '.docstring').readAsStringSync();
    } on FileSystemException {
      // if (debug.debug)
      // Config.logger.i('docstring not found for ${builtin.path}');
      if (debug.debug) {
        docString = warningPen('${tName}.docstring not found');
        // tName = warningPen(sprintf('%-18s', [tName]));
      }
    }
    tName = sprintf('%-18s', [tName]);
    print('\t${tName} ${docString}');
  });
}

Future<Map> listBuiltinTemplates() async {
  // ArgResults options) async {
  // print('printBuiltins ${options.arguments}');
  //Uri
  // var packageConfigUri = await Isolate.packageConfig;
  // // e.g. file:///Users/gar/mobileink/dartrix/.packages
  // if (Config.debug) {
  //   Config.logger.i('packageConfigUri $packageConfigUri');
  // }

  // WARNING: for pub global activateds, the current dir of the script contains
  // .packages, which is the value of Isolate.packageConfig, but it does NOT
  // contain all of the subdirs of the original pkg root. It only the bin dir,
  // plus the pub stuff (.dart_tool, .packages, pubspec.lock).

  // e.g.
  // $ l ~/.pub-cache/global_packages/stagehand/
  // total 8.0K
  // drwxr-xr-x 3 gar staff  102 Mar 10 18:40 .dart_tool/
  // -rw-r--r-- 1 gar staff 2.9K Mar 10 18:40 .dart_tool/package_config.json
  // -rw-r--r-- 1 gar staff 1.3K Mar 10 18:40 .packages
  // drwxr-xr-x 3 gar staff  102 Mar 10 18:40 bin/
  // -rw-r--r-- 1 gar staff 1.3M Mar 10 18:40 bin/stagehand.dart.snapshot.dart2
  // -rw-r--r-- 1 gar staff 2.4K Mar 10 18:40 pubspec.lock

  // So to find the templates/ dir, we have to look it up in the .packages file
  // using findPackageConfigUri.  this is a v1 pkg config, i.e. a .packages
  // file, so back up one segment: String libDir =
  // path.dirname(packageConfigUri.path); var templatesRoot =
  // path.dirname(packageConfigUri.path) + '/templates'; List

  var templatesRoot = await resolveBuiltinTemplatesRoot();
  var templates = Directory(templatesRoot).listSync()
    ..retainWhere((f) => f is Directory);

  var tlist = {
    for (var tdir in templates)
      path.basename(tdir.path): {
        'root': tdir.path,
        'docstring': getDocString(templatesRoot, tdir)
      },
  };
  return tlist;
}

// final Logger _logfoo = Logger('foo')
// ..onRecord.listen((record) {
//     print('${record.loggerName} ${infoPen(record.level.name)}: ${record.message}');
// });
// final Logger _log = Logger('foo.bar')
// ..onRecord.listen((record) {
//     print('${record.loggerName} ${infoPen(record.level.name)}: ${record.message}');
// });
//var _log = Logger('builtin');

/// Initialize builtinTemplates variable (Set).
///
/// Read the <root>/templates directory, retaining only directory entries. Each
/// subdirectory represents one template.
void initBuiltinTemplates() async {
  // Config.logger.i('builtins.initBuiltinTemplates');

  //String
  var templatesRoot = await resolveBuiltinTemplatesRoot();

  //List
  var builtins = Directory(templatesRoot).listSync();
  builtins.retainWhere((f) => f is Directory);
  // print('getBuiltinTemplates: $builtins');
  //builtinTemplates =
  // builtins.map<String,String>((d) {
  builtins.forEach((builtin) {
    // String
    var basename = path.basename(builtin.path);
    // String
    var docstring;
    try {
      docstring = File(builtin.path + '.docstring').readAsStringSync();
    } on FileSystemException {
      // if (debug.debug)
      // Config.logger.i('docstring not found for ${builtin.path}');
    }
    builtinTemplates[basename] = docstring ?? '';
  });
  if (debug.debug) debug.debugListBuiltins();
}

void generateFromBuiltin(String template) async {
  // Config.prodLogger.v('generateFromBuiltin');

  if (Config.debug) {
    debug.debugData({});
  }
  //String
  var templatesRoot = await resolveBuiltinTemplatesRoot();
  // _log.finer('templatesRoot: $templatesRoot');

  // String templateRoot = templatesRoot + '/' + Config.options['template'];
  // // _log.finer('template root: $templateRoot');

  List tFileset =
      Directory(templatesRoot + '/' + template) //Config.options['template'])
          .listSync(recursive: true);
  tFileset.removeWhere((f) => f.path.endsWith('~'));
  tFileset.retainWhere((f) => f is File);

  if (Config.verbose) {
    Config.prodLogger.i('Generating files from templates and copying assets...');
  }

  // We iterate over all template content twice, first to get a list of
  // overwrites, then to overwrite.

  // prevent unauthorized overwrites

  var overWrites = [];
  var exists;
  if (!tData['dartrix']['force']) {
    tFileset.forEach((tfile) {
      // Config.logger.v('cwd: ${Directory.current.path}');
      // Config.logger.v('tfile: $tfile');
      // Config.logger.v('tData[\'out\']: ${tData['out']}');
      var templateOutPath =
          tfile.path.replaceFirst(templatesRoot + '/' + template + '/', '');
      // templatesRoot + '/' + Config.options['template'] + '/', '');
      // Config.logger.v('templateOutPath: $templateOutPath');
      var outSubpath = path.normalize(tData['out'] + templateOutPath);
      outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');
      // Config.logger.v('outSubpath: $outSubpath');

      outSubpath = path.normalize(rewritePath(outSubpath));
      // Config.logger.v('rewritten outSubpath: $outSubpath');

      // if (path.isRelative(outSubpath)) {
      //   outSubpath = Directory.current.path + '/' + outSubpath;
      // }

      exists = FileSystemEntity.typeSync(outSubpath);
      if (exists != FileSystemEntityType.notFound) {
        if (exists == FileSystemEntityType.file) {
          if (!tData['dartrix']['force']) {
            // Config.prodLogger.e(
            //     'ERROR: $outSubpath already exists. Use -f to force overwrite.');
            // exit(0);
            overWrites.add(outSubpath);
          } else {
            if ((Config.verbose) || Config.dryRun) {
              Config.prodLogger.i('Over-writing $outSubpath');
            }
          }
        }
      }
    });
  }

  if (overWrites.isNotEmpty) {
    Config.prodLogger.w('This template would overwrite the following files:');
    overWrites.forEach((f) {
      Config.prodLogger.w('overwrite warning: ${path.canonicalize(f)}');
    });
    Config.prodLogger.w('Rerun with flag "-f" (--force) to force overwrite.');
    exit(0);
  }
  tFileset.forEach((tfile) {
    // _log.finer('tfile: $tfile');

    // first remove template name prefix path
    var outSubpath = path.normalize(tData['out'] +
        tfile.path.replaceFirst(templatesRoot + '/' + template, ''));
    // templatesRoot + '/' + Config.options['template'], ''));
    // then remove mustache extension
    outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');
    // now rewrite and normalize outpath
    // result is normalized absolute path
    // outSubpath = path.normalize(rewritePath(outSubpath));
    outSubpath = rewritePath(outSubpath);
    // _log.finer('rewritten outSubpath: $outSubpath');

    if (path.isRelative(outSubpath)) {
      outSubpath = Directory.current.path + '/' + outSubpath;
    }
    // Config.logger.i('absolutized outSubpath: $outSubpath');

    // create output dir if necessary
    var dirname = path.dirname(outSubpath);
    // Config.logger.i("dirname: $dirname");
    exists = FileSystemEntity.typeSync(dirname);
    if (exists == FileSystemEntityType.notFound) {
      if ((Config.verbose) || Config.dryRun) {
        Config.prodLogger.i('Creating output directory: $dirname');
      }
      if (!Config.dryRun) {
        Directory(dirname).createSync(recursive: true);
      }
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
        Config.debugLogger.e(e);
        exit(0);
      }
      // _log.finer(newContents);
      if ((Config.verbose) || Config.dryRun) {
        if (debug.debug) {
          Config.debugLogger.i('   ' + tfile.path);
        }
        Config.prodLogger.i('=> $outSubpath');
      }
      if (!Config.dryRun) {
        File(outSubpath).writeAsStringSync(newContents);
      }
    } else {
      if ((Config.verbose) || Config.dryRun) {
        if (debug.debug) {
          Config.debugLogger.i('   ' + tfile.path);
        }
        Config.prodLogger.i('=> $outSubpath');
      }
      if (!Config.dryRun) {
        tfile.copySync(outSubpath);
      }
    }
  });
  var action;
  if (Config.dryRun) {
    action = 'would generate';
  } else {
    action = 'generated';
  }
  Config.prodLogger
      .i('Template ${template} ${action} ${tFileset.length} files.');
}

void printDartrixUsage() {
  print(
      'Dartrix template library. A collection of general templates for softwared development.  Mainly but not exclusively Dart and Flutter code.');
}

void dispatchBuiltin(ArgResults _options, List<String> subArgs) async {
  // Config.debugLogger.d('dispatchBuiltin');
  // print('option args: ${_options.arguments}');
  // print('option rest: ${_options.rest}');

  if (_options.wasParsed('help')) {
    // Config.logger.i('new HELP');
    // exit(0);
  }

  // var subArgs = _options.rest.toList();
  var dartrixArgs;
  var tArgs;

  var ft;
  var template;
  ft = subArgs.indexOf('--template');
  if (ft < 0) {
    // not found
    ft = subArgs.indexOf('-t');
    if (ft < 0) {
      // not found
      Config.prodLogger.e('Missing required template option: -t | --template');
      exit(0);
    } else {
      // Config.logger.e('found -t');
      if (ft != subArgs.lastIndexOf('-t')) {
        Config.prodLogger.e('Multiple --template options not allowed.');
        exit(0);
      }
      if (subArgs.contains('--template')) {
        Config.prodLogger.e('Only one -t or --template option allowed.');
        exit(0);
      }
      template = subArgs[ft + 1];
      dartrixArgs = subArgs.sublist(0, ft);
      tArgs = subArgs.sublist(ft + 2);
    }
  } else {
    // Config.logger.e('found --template');
    if (ft != subArgs.lastIndexOf('--template')) {
      Config.prodLogger.e('Only one -t or --template option allowed.');
      exit(0);
    }
    if (subArgs.contains('-t')) {
      Config.prodLogger.e('Only one -t or --template option allowed.');
      exit(0);
    }
    template = subArgs[ft + 1];
    dartrixArgs = subArgs.sublist(0, ft);
    tArgs = subArgs.sublist(ft + 2);
  }
  // print('template: $template');
  // print('dartrixArgs: $dartrixArgs');
  // print('tArgs: $tArgs');

  if (dartrixArgs.contains('-h') || dartrixArgs.contains('--help')) {
    printDartrixUsage();
  }

  var templates = await listBuiltinTemplates();
  // print('bt: $templates, rtt: ${templates.runtimeType}');
  if (templates.keys.contains(template)) {
    // print('found template $template in lib');
    // debugging:
    // var pkg = templates[template];
    // Config.logger.i('pkg: $pkg, rtt: ${pkg.runtimeType}');
    // var r = pkg['root'];
    // Config.debugLogger.i('root: $r');
    switch(template) {
      case 'bashrc':
      await handleBashrc(templates[template]['root'], tArgs);
      break;
      case 'dart_cmdsuite':
      await handleDartCmdSuite(templates[template]['root'], tArgs);
      break;
      default:
      Config.prodLogger.e('No handler for template $template');
    }
  } else {
    Config.prodLogger.e('template $template not found in lib');
  }
}
