import 'dart:io';

import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/paths.dart';

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

/// Run builtin template. The template is stored in Config.templateRoot.
void generateFromBuiltin() async {
  // Config.prodLogger.v('generateFromBuiltin entry');

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
  tFileList.removeWhere((f) => f.path.endsWith('/.yaml'));
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
      var templateOutPath = tfile.path.replaceFirst(
        Config.templateRoot + '/', '');
      // tfile.path.replaceFirst(templatesRoot + '/' + template + '/', '');
      // tfile.path.replaceFirst(templatesRoot + '/' + template + '/', '');
      // templatesRoot + '/' + Config.options['template'] + '/', '');
      // Config.logger.v('templateOutPath: $templateOutPath');
      // var outSubpath = path.canonicalize(tData['out'] + templateOutPath);
      var outSubpath = templateOutPath.replaceFirst(RegExp('\.mustache\$'), '');
      // Config.logger.v('outSubpath: $outSubpath');

      // debug.debugData({});
      outSubpath = path.canonicalize(rewritePath(outSubpath));
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
    var outSubpath = path.canonicalize(// tData['out'] +
        tfile.path.replaceFirst(Config.templateRoot + '/', ''));
    // tfile.path.replaceFirst(templatesRoot + '/' + template, ''));
    // templatesRoot + '/' + Config.options['template'], ''));
    if (Config.debug) {
      Config.ppLogger.v('outSubpath template: $outSubpath');
    }
    // then remove mustache extension
    outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');
    
    // result is canonicalized absolute path
    // outSubpath = path.canonicalize(rewritePath(outSubpath));
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
      for (var f in writtenFiles) path.canonicalize(path.dirname(f)),
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
