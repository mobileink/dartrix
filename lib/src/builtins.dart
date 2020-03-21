import 'dart:io';
import 'dart:isolate';

// import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;

import 'package:dartrix/src/handlers/bashrc.dart';
import 'package:dartrix/src/handlers/dart_clix.dart';

var _log = Logger('builtin');

Future<String> getBuiltinTemplatesRoot() async {
  // Procedure: get path to app pkg root (as opposed to the package UriRoot,
  // which is the package's lib/ dir).  In this case the package is
  // package:dartrix; the pkg root is ~/mobileink/dartrix, and the package
  // UriRoot is ~/mobileink/dartrix/lib.  The templates are in the package
  // root, not the package UriRoot.

  // So to find the templates, we need to find the package root.

  // Location of "currently running Dart script": dart:io/Platform.script
  // Current Working Directory: dart:io/Directory.current
  // Current Isolate

  // _log.info('cwd: ${Directory.current}');
  // e.g. Directory: '/Users/gar/tmp/dartrix'

  // String scriptPath = path.prettyUri(Platform.script.toString());
  // relative path, e.g. ../../mobileink/dartrix/bin/new.dart
  // _log.info('platformScriptPath: ${scriptPath}');
  // _log.info('platformScriptPath, normalized: ${path.normalize(scriptPath)}');
  // _log.info('platformScriptPath, canonical: ${path.canonicalize(scriptPath)}');

  //Uri
  var currentIsoPkgConfigUri = await Isolate.packageConfig;
  // e.g. file:///Users/gar/mobileink/dartrix/.packages
  // _log.info('currentIsoPkgConfigUri: $currentIsoPkgConfigUri');

  // Isolate.packageConfig finds the version 1 .packages file;
  // use that to get the PackageConfig and you get the contents
  // of the version 2 .dart_tool/package_config.json
  // findPackageConfigUri is a fn in package:package_confg
  //PackageConfig
  var pkgConfig = await findPackageConfigUri(currentIsoPkgConfigUri);
  // _log.info('current iso PackageConfig: $pkgConfig');
  // PackageConfig is an object containing list of deps
  // if (debug.debug) debug.debugPackageConfig(pkgConfig);

  // 'Package': 'map' with keys name, packageUriRoot, and root (=pkgRoot)
  // Package
  var appConfig = pkgConfig.packages.firstWhere((pkg) {
    return pkg.name == Config.appName;
  });
  // _log.info('appConfig: ${appConfig.name} : ${appConfig.root}');
  //String
  var templatesRoot = appConfig.root.path + '/templates';
  // using scriptPath is undoubtedly more efficient
  // String templatesRoot = path.dirname(scriptPath) + '/../templates';
  templatesRoot = path.canonicalize(templatesRoot);
  // _log.info('templatesRoot: $templatesRoot');
  return templatesRoot;
}

/// Initialize builtinTemplates variable (Set).
///
/// Read the <root>/templates directory, retaining only directory entries. Each
/// subdirectory represents one template.
void initBuiltinTemplates() async {
  // _log.info('builtins.initBuiltinTemplates');

  //String
  var templatesRoot = await getBuiltinTemplatesRoot();

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
      // _log.info('docstring not found for ${builtin.path}');
    }
    builtinTemplates[basename] = docstring ?? '';
  });
  if (debug.debug) debug.debugListBuiltins();
}

void generateFromBuiltin() async {
  // _log.finer('generateFromBuiltin');

  //String
  var templatesRoot = await getBuiltinTemplatesRoot();
  // _log.finer('templatesRoot: $templatesRoot');

  // String templateRoot = templatesRoot + '/' + Config.options['template'];
  // // _log.finer('template root: $templateRoot');

  List tFileset = Directory(templatesRoot + '/' + Config.options['template'])
      .listSync(recursive: true);
  tFileset.removeWhere((f) => f.path.endsWith('~'));
  tFileset.retainWhere((f) => f is File);

  if (Config.verbose) {
    _log.info('Generating files from templates and copying assets...');
  }

  // prevent unauthorized overwrites
  var overWrites = [];
  var exists;
  tFileset.forEach((tfile) {
    var outSubpath = path.normalize(tData['out'] +
        tfile.path.replaceFirst(
            templatesRoot + '/' + Config.options['template'], ''));
    outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');
    // _log.finer('outSubpath: $outSubpath');
    outSubpath = path.normalize(rewritePath(outSubpath));
    // _log.finer('rewritten outSubpath: $outSubpath');

    if (path.isRelative(outSubpath)) {
      outSubpath = Directory.current.path + '/' + outSubpath;
    }

      exists = FileSystemEntity.typeSync(outSubpath);
      if (exists != FileSystemEntityType.notFound) {
        if (exists == FileSystemEntityType.file) {
          if (!tData['dartrix']['force']) {
            // _log.severe(
            //     'ERROR: $outSubpath already exists. Use -f to force overwrite.');
            // exit(0);
            overWrites.add(outSubpath);
          } else {
            if ((Config.verbose) || Config.options['dry-run']) {
              _log.warning('Over-writing $outSubpath');
            }
          }
        }
      }
  });

  if (overWrites.isNotEmpty) {
    _log.warning('This template would overwrite the following files:');
    overWrites.forEach((f) => _log.warning(f));
    _log.warning('Rerun with flag "-f" (--force) to force overwrite.');
    exit(0);
  }

  tFileset.forEach((tfile) {
    // _log.finer('tfile: $tfile');
    var outSubpath = path.normalize(tData['out'] +
        tfile.path.replaceFirst(
            templatesRoot + '/' + Config.options['template'], ''));
    outSubpath = outSubpath.replaceFirst(RegExp('\.mustache\$'), '');
    // _log.finer('outSubpath: $outSubpath');
    outSubpath = path.normalize(rewritePath(outSubpath));
    // _log.finer('rewritten outSubpath: $outSubpath');

    if (path.isRelative(outSubpath)) {
      outSubpath = Directory.current.path + '/' + outSubpath;
    }
    // _log.finer('absolutized outSubpath: $outSubpath');

    // create output dir if necessary
    var dirname = path.dirname(outSubpath);
    // _log.info("dirname: $dirname");
    exists = FileSystemEntity.typeSync(dirname);
    if (exists == FileSystemEntityType.notFound) {
      if ((Config.verbose) || Config.options['dry-run']) {
        _log.info('Creating output directory: $dirname');
      }
      if (!Config.options['dry-run']) {
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
        _log.severe(e);
        exit(0);
      }
      // _log.finer(newContents);
      if ((Config.verbose) || Config.options['dry-run']) {
        if (debug.debug) {
          _log.info('   ' + tfile.path);
        }
        _log.info('=> $outSubpath');
      }
      if (!Config.options['dry-run']) {
        File(outSubpath).writeAsStringSync(newContents);
      }
    } else {
      if ((Config.verbose) || Config.options['dry-run']) {
        if (debug.debug) {
          _log.info('   ' + tfile.path);
        }
        _log.info('=> $outSubpath');
      }
      if (!Config.options['dry-run']) {
        tfile.copySync(outSubpath);
      }
    }
  });
}

void dispatchBuiltin(String template) async {
  // _log.info('dispatchBuiltin');
  var tIndex = Config.options.arguments.indexOf('-t');
  //List<String>
  var subArgs = Config.options.arguments.sublist(tIndex + 2);
  // _log.info('subArgs: $subArgs');
  switch (template) {
    case 'bashrc': handleBashrc(subArgs); break;
    case 'dart_clix': handleDartClix(subArgs); break;
    default:
    _log.info("handler for $template not implemented");
  }
  // generateFromBuiltin(template, options);
}
