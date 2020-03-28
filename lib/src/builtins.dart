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
import 'package:dartrix/src/dispatch.dart';
import 'package:dartrix/src/handlers/dart_cmdsuite.dart';
import 'package:dartrix/src/handlers/bashrc.dart';
import 'package:dartrix/src/paths.dart';
import 'package:dartrix/src/resolver.dart';
// import 'package:dartrix/src/utils.dart';

void printBuiltins() async {
  // var templatesRoot = await resolveBuiltinTemplatesRoot();
  // var templates = Directory(templatesRoot).listSync()
  //   ..retainWhere((f) => f is Directory);

  var templates = await getTemplatesMap(null);

  print('Builtin templates:');
  templates.forEach((tName, spec) {
    // var tName = path.basename(t.path);
    //String
    var docString;
    var dspath = spec['root'] + '.docstring';
    try {
      docString = File(dspath).readAsStringSync();
    } on FileSystemException {
      // if (debug.debug)
      Config.prodLogger.w('docstring not found for ${dspath}');
      // if (debug.debug) {
      //   docString = warningPen('${tName}.docstring not found');
      // tName = warningPen(sprintf('%-18s', [tName]));
    }
    tName = sprintf('%-18s', [tName]);
    print('\t${tName} ${docString}');
  });
}

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

/// Run builtin template. The template is stored in Config.templateRoot.
void generateFromBuiltin() async {
  // Config.prodLogger.v('generateFromBuiltin');

  if (Config.debug) {
    debug.debugData({});
  }
  //String
  // var templatesRoot = await resolveBuiltinTemplatesRoot();
  // _log.finer('templatesRoot: $templatesRoot');

  // String templateRoot = templatesRoot + '/' + Config.options['template'];
  // // _log.finer('template root: $templateRoot');

  // List tFileList =
  //     Directory(templatesRoot + '/' + template) //Config.options['template'])
  //         .listSync(recursive: true);

  var template = path.basename(Config.templateRoot);
  // Config.logger.v('template: $template');
  List tFileList = Directory(Config.templateRoot).listSync(recursive: true);

  tFileList.removeWhere((f) => f.path.endsWith('~'));
  tFileList.retainWhere((f) => f is File);

  if (Config.verbose) {
    Config.ppLogger.i('Generating files from templates and copying assets...');
  }

  // We iterate over all template content twice, first to get a list of
  // overwrites, then to overwrite.

  // prevent unauthorized overwrites

  var overWrites = [];
  var exists;
  if (!tData['dartrix']['force']) {
    tFileList.forEach((tfile) {
      // Config.logger.v('cwd: ${Directory.current.path}');
      // Config.logger.v('tfile: $tfile');
      // Config.logger.v('tData[\'out\']: ${tData['out']}');
      var templateOutPath = tfile.path.replaceFirst(Config.templateRoot, '');
      // tfile.path.replaceFirst(templatesRoot + '/' + template + '/', '');
      // tfile.path.replaceFirst(templatesRoot + '/' + template + '/', '');
      // templatesRoot + '/' + Config.options['template'] + '/', '');
      // Config.logger.v('templateOutPath: $templateOutPath');
      // var outSubpath = path.normalize(tData['out'] + templateOutPath);
      var outSubpath = templateOutPath.replaceFirst(RegExp('\.mustache\$'), '');
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
    Config.ppLogger
        .w('Canceling - this template would overwrite the following files:');
    overWrites.forEach((f) {
      Config.prodLogger.w('\t${path.canonicalize(f)}');
    });
    Config.ppLogger.i('Rerun with flag -f or --force to force overwrite.');
    exit(0);
  }

  var writtenFiles = [];

  tFileList.forEach((tfile) {
    // _log.finer('tfile: $tfile');

    // first remove template name prefix path
    var outSubpath = path.normalize(// tData['out'] +
        tfile.path.replaceFirst(Config.templateRoot, ''));
    // tfile.path.replaceFirst(templatesRoot + '/' + template, ''));
    // templatesRoot + '/' + Config.options['template'], ''));
    if (Config.debug) {
      Config.ppLogger.v('outSubpath template: $outSubpath');
    }
    // then remove mustache extension
    outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');
    // now rewrite and normalize outpath
    // result is normalized absolute path
    // outSubpath = path.normalize(rewritePath(outSubpath));
    outSubpath = rewritePath(outSubpath);
    if (Config.debug) {
      Config.ppLogger.v('rewritten outSubpath: $outSubpath');
    }
    if (path.isRelative(outSubpath)) {
      outSubpath = Directory.current.path + '/' + outSubpath;
    }
    if (Config.debug) {
      Config.ppLogger.v('absolutized outSubpath: $outSubpath');
    }
    // create output dir if necessary
    var dirname = path.dirname(outSubpath);
    // Config.logger.i("dirname: $dirname");
    exists = FileSystemEntity.typeSync(dirname);
    if (exists == FileSystemEntityType.notFound) {
      if ((Config.verbose) || Config.dryRun) {
        // Config.logger.i('Creating output directory: $dirname');
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
          Config.prodLogger.v('   ' + tfile.path);
        }
        Config.prodLogger.v('=> $outSubpath');
      }
      if (!Config.dryRun) {
        File(outSubpath).writeAsStringSync(newContents);
        writtenFiles.add(outSubpath);
      }
    } else {
      if ((Config.verbose) || Config.dryRun) {
        if (debug.debug) {
          Config.debugLogger.v('   ' + tfile.path);
        }
        Config.prodLogger.v('=> $outSubpath');
      }
      if (!Config.dryRun) {
        tfile.copySync(outSubpath);
        writtenFiles.add(outSubpath);
      }
    }
  });

  //List<String>
  var outdir;
  if (writtenFiles.isNotEmpty) {
    var outs = [
      for (var f in writtenFiles) path.normalize(path.dirname(f)),
    ];
    outs.sort((a, b) => a.length.compareTo(b.length));
    outdir = outs.first;
  }

  var action;
  if (Config.dryRun) {
    action = 'would generate';
  } else {
    action = 'generated';
  }
  Config.ppLogger.i(
      'Template ${template} ${action} ${tFileList.length} files to ${outdir}');
}

void printDartrixUsage() {
  print(
      'Dartrix template library. A collection of general templates for softwared development.  Mainly but not exclusively Dart and Flutter code.');
}

// FIXME: _options == Config.options
void dispatchBuiltin(String template, ArgResults _options,
    List<String> dartrixArgs, List<String> tArgs) async {
  // Config.debugLogger.d('dispatchBuiltin');
  // print('option args: ${_options.arguments}');
  // print('option rest: ${_options.rest}');

  await processArgs('dartrix', template, _options, dartrixArgs, tArgs);

  // if (_options.wasParsed('help') ||
  //     dartrixArgs.contains('-h') ||
  //     dartrixArgs.contains('--help')) {
  //   print('Library: dartrix');
  //   printDartrixUsage();
  // }

  var templates = await getTemplatesMap(null); // listBuiltinTemplates();
  // // print('bt: $templates, rtt: ${templates.runtimeType}');
  if (templates.keys.contains(template)) {
    //   // print('found template $template in lib');
    //   // debugging:
    //   // var pkg = templates[template];
    //   // Config.logger.i('pkg: $pkg, rtt: ${pkg.runtimeType}');
    //   // var r = pkg['root'];
    //   // Config.debugLogger.i('root: $r');

    //   Config.templateRoot = templates[template]['root'];

    //   await processYamlArgs(Config.templateRoot, tArgs);

    switch (template) {
      case 'bashrc':
        // await handleBashrc(templates[template]['root'], tArgs);
        await handleBashrc(Config.templateRoot, tArgs);
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
