import 'dart:io';

import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/paths.dart';

/// Run builtin template. The template is stored in Config.templateRoot.
void processTemplate() async {
  // Config.prodLogger.v('processTemplate entry');
  if (Config.debug) {
    debug.debugData({});
  }

  var template = path.basename(Config.templateRoot);
  // Config.logger.v('template: $template');
  List tFileList = Directory(Config.templateRoot).listSync(recursive: true);
  // print('templateRoot: ${Config.templateRoot}');
  // print('''38b47cdc-2bed-4e59-b576-b0008908d598:  Config.genericIndex: ${Config.genericIndex}''');
  if (Config.generic) {
    // print('''f91cfca5-76da-45de-a141-00e7efd29682:  ''');
    // print('gen index: ${Config.genericIndex}');
    tFileList.retainWhere((f) {
      var tpath = f.path.replaceFirst(Config.templateRoot + '/', '');
      // print('''1d99de6b-6648-4c9f-b1ec-33db63854fa7:  ''');
      // print('tpath: $tpath');
      return (tpath.startsWith(Config.genericSelection) ||
          tpath.startsWith(Config.genericIndex));
    });
  }

  tFileList.removeWhere((f) => f.path.endsWith('~'));
  // remove all dotfiles - users must use e.g. DOTgitignore
  tFileList.removeWhere((f) {
    var tpath = f.path.replaceFirst(Config.templateRoot + '/', '');
    // print('tpath: $tpath');
    return tpath.startsWith('.');
  });
  tFileList.retainWhere((f) => f is File);

  if (Config.verbose) {
    Config.ppLogger.i('Generating files from templates and copying assets...');
  }

  // We iterate over all template content twice, first to get a list of
  // overwrites, then to overwrite.

  // prevent unauthorized overwrites

  var overWrites = [];
  var exists;
  if (!Config.force) {
    tFileList.forEach((tfile) {
      // Config.logger.v('cwd: ${Directory.current.path}');
      // print('''6b29edec-6503-4ca6-8a7b-b639efd50085:  tfile: $tfile''');
      // Config.logger.v('tData[\'out\']: ${tData['out']}');
      var templateOutPath =
          tfile.path.replaceFirst(Config.templateRoot + '/', '');
      // print('''ea344d35-e2a9-444c-9316-0b68a52f33cc: tout: $templateOutPath''');

      if (Config.generic) {
        templateOutPath =
            templateOutPath.replaceFirst(Config.genericSelection + '/', '');
        templateOutPath =
            templateOutPath.replaceFirst(Config.genericIndex + '/', '');
      }

      // print('''67089817-65a9-4816-badc-d31a794133a7:  top $templateOutPath''');

      // tfile.path.replaceFirst(templatesRoot + '/' + template + '/', '');
      // tfile.path.replaceFirst(templatesRoot + '/' + template + '/', '');
      // templatesRoot + '/' + Config.options['template'] + '/', '');
      // Config.logger.v('templateOutPath: $templateOutPath');
      // var outSubpath = path.canonicalize(tData['out'] + templateOutPath);
      var outSubpath = templateOutPath.replaceFirst(RegExp('\.mustache\$'), '');
      // print('''28d0b06d-9f3e-4d81-b55b-ee15a0a9d644: outSubpath: $outSubpath''');
      outSubpath = rewritePath(outSubpath);
      // print('''6a3052a8-c978-444c-bb71-6bc5fca84632:  rewritten: $outSubpath''');
      outSubpath = path.canonicalize(outSubpath);

      // print('''7d95ce0a-bd18-493b-ba94-5e9fe10522cb: canonicalized: $outSubpath''');

      // if (path.isRelative(outSubpath)) {
      //   outSubpath = Directory.current.path + '/' + outSubpath;
      // }

      exists = FileSystemEntity.typeSync(outSubpath);
      if (exists != FileSystemEntityType.notFound) {
        if (exists == FileSystemEntityType.file) {
          if (!Config.force) {
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
    Config.ppLogger.i('Rerun with --force to force overwrite.');
    exit(0);
  }

  var writtenFiles = [];

  // print('''bb0cb6ae-c8a5-443a-85d8-62fab16495b4:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX''');
  tFileList.forEach((tfile) {
    // print('''65dc3ff0-f236-493e-b189-2f3b1c5c0735:  tfile: $tfile''');
    // print('''9aa446a9-5ff3-4cad-b9f1-3787f57d58c6:  templateRoot ${Config.templateRoot}''');

    // first remove template name prefix path
    var outSubpath = // path.canonicalize(// tData['out'] +
        tfile.path.replaceFirst(Config.templateRoot + '/', '');
    // print('''7569853d-bb21-4a44-b2c9-65da3a529288:  outSubpath1: $outSubpath''');
    // ditto if this is a generic
    if (Config.generic) {
      outSubpath = outSubpath.replaceFirst(Config.genericIndex + '/', '');
      outSubpath = outSubpath.replaceFirst(Config.genericSelection + '/', '');
    }

    // print('''0491394c-3f0c-4726-a2ee-9717767280bd:  outSubpath2: $outSubpath''');
    // then remove mustache extension
    outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');

    if (Config.debug) {
      print('''bc425375-685c-45b1-bd39-a539cf6ad739:  ''');
      Config.ppLogger.v('outSubpath: $outSubpath');
    }
    // result is canonicalized absolute path
    // outSubpath = path.canonicalize(rewritePath(outSubpath));
    // outSubpath = rewritePath(outSubpath);
    outSubpath = path.canonicalize(rewritePath(outSubpath));
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
        // print('''7b838d7f-de1b-47de-9f62-dc4ec00312d2:  ''');
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
    // print('''30d09eef-b888-4d14-a131-1bfc85bf57e8:  LOOPING''');
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

void fixpoint(bool here) async {
  // Config.prodLogger.v('fixpoint entry ================================================================');
  if (Config.debug) {
    debug.debugData({});
  }

  var template = path.basename(Config.templateRoot);
  // print('''6d802239-1083-4d7b-8572-fe7e4b8d6861:  templateRoot: $template''');
  List tFileList = Directory(Config.templateRoot).listSync(recursive: true);

  //FIXME: add .dartrixignore?
  // tFileList.removeWhere((f) => f.path.endsWith('~'));
  tFileList.retainWhere((f) => f is File);
  // tFileList.forEach((f) => print('''b3ab431b-3ff9-424f-bff7-7872e1ef90f7:  infile: $f'''));

  if (Config.verbose) {
    Config.ppLogger.i('Fixed point processing...');
  }

  // We iterate over all template content twice, first to get a list of
  // overwrites, then to overwrite.

  // prevent unauthorized overwrites

  var overWrites = [];
  var exists;
  if (!Config.force) {
    // print('''7a13735c-a850-4572-8ea8-7d57d54be993:  Overwrite check ================''');
    tFileList.forEach((tfile) {
      // Config.logger.v('cwd: ${Directory.current.path}');
      // Config.ppLogger.i('''6b29edec-6503-4ca6-8a7b-b639efd50085:  infile: $tfile''');
      var outSubpath = tfile.path.replaceFirst(Config.templateRoot + '/', '');
      // print('''ea344d35-e2a9-444c-9316-0b68a52f33cc: outSubpath: $outSubpath''');

      // No rewriting for Fixpoints
      // outSubpath = rewritePath(outSubpath);
      // print('''af36839b-3909-4bac-8f78-308b9015b68c: rewritten: $outSubpath''');

      // print('''a4781e5e-bae9-4611-b765-4149496a44fc:  here? ${here}''');
      // outSubpath = (here ? '.templates/' : 'templates/')
      outSubpath = (here ? Config.hereDir + '/templates/' : 'templates/') +
          template +
          '/' +
          outSubpath;
      // print('''561f1948-5678-4fbf-99f1-66dff773706a:  prefixed: $outSubpath''');

      outSubpath = path.canonicalize(outSubpath);
      // print('''af36839b-3909-4bac-8f78-308b9015b68c: canonicalized: $outSubpath''');

      exists = FileSystemEntity.typeSync(outSubpath);
      if (exists == FileSystemEntityType.notFound) {
        // print('''2a9bcb4b-a951-4173-8693-62c400602ec7:  not found''');
      } else if (exists != FileSystemEntityType.notFound) {
        // print('''2a9bcb4b-a951-4173-8693-62c400602ec7:  exists''');
        overWrites.add(outSubpath);
        // } else {
        // if ((Config.verbose) || Config.dryRun) {
        //   Config.prodLogger.i('Over-writing $outSubpath');
        // }
      }
    });
    // print('''eef8935a-a56d-4cee-8715-611e7196726c: Overwrite check complete ================''');
  } //  if (!Config.force)

  if (overWrites.isNotEmpty) {
    Config.ppLogger
        .w('Canceling - this template would overwrite the following files:');
    overWrites.forEach((f) {
      Config.prodLogger.w('\t${path.canonicalize(f)}');
    });
    Config.ppLogger.i('Rerun with --force to force overwrite.');
    exit(0);
  }

  var writtenFiles = [];

  // print('''bb0cb6ae-c8a5-443a-85d8-62fab16495b4:  writing files ================''');
  tFileList.forEach((tfile) {
    // print('''65dc3ff0-f236-493e-b189-2f3b1c5c0735:  infile: $tfile''');

    // first remove template name prefix path
    var outSubpath = tfile.path.replaceFirst(Config.templateRoot + '/', '');
    // print('''7569853d-bb21-4a44-b2c9-65da3a529288:  outSubpath: $outSubpath''');

    if (Config.debug) {
      print('''bc425375-685c-45b1-bd39-a539cf6ad739:  ''');
      Config.ppLogger.v('outSubpath: $outSubpath');
    }

    //FIXME: support --name
    // print('''4f9ee631-160b-4daa-9f07-165066033cda:  NAME: ${tData["name"]}''');

    outSubpath = (here ? Config.hereDir + '/templates/' : 'templates/') +
        template +
        '/' +
        outSubpath;
    // print('''561f1948-5678-4fbf-99f1-66dff773706a:  prefixed: $outSubpath''');

    outSubpath = path.canonicalize(outSubpath);
    // print('''af36839b-3909-4bac-8f78-308b9015b68c: canonicalized: $outSubpath''');

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
        // print('''23cb60b1-c355-46c0-be61-7903d6f3d9bd:  created dir: $dirname''');
      }
    }

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
    action = 'would write';
  } else {
    action = 'wrote';
  }
  Config.ppLogger.i(
      'Template ${template} ${action} ${tFileList.length} files to ${outdir}');
}
