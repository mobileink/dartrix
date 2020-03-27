// import 'dart:async';
import 'dart:io';
// import 'dart:isolate';

import 'package:args/args.dart';
// import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
// import 'package:dartrix/src/debug.dart' as debug;
// import 'package:dartrix/src/paths.dart';
// import 'package:dartrix/src/utils.dart';

// void dispatchPlugin(String pkg, String template, List<String> args) async {
//   // Config.debugLogger.v('dispatchPlugin: $pkg, $template, $args');

// FIXME: _options == Config.options
void processArgs(String pkg, String template, ArgResults _options,
    List<String> libArgs, List<String> tArgs) async {
  // Config.ppLogger.v('processArgs $pkg, $template, $_options, $libArgs, $tArgs');

  if (_options.wasParsed('help') ||
      libArgs.contains('-h') ||
      libArgs.contains('--help') ||
      tArgs.contains('-h') ||
      tArgs.contains('--help')) {
    print('\nLibrary \'$pkg\' options:');
    // printDartrixUsage();
  }

  // var pkgRoot = await resolvePkgRoot(pkg); // 'package:' + pkg + '_dartrix');
  // if (Config.verbose) {
  //   Config.ppLogger.v('resolved $pkg to package:${pkg}_dartrix to $pkgRoot');
  // }

  var templates = await getTemplatesMap(Config.libPkgRoot);
  // Config.debugLogger.v(templates);

  Config.templateRoot = Config.libPkgRoot + 'templates/' + template;
  // Config.debugLogger.v('Config.templateRoot: ${Config.templateRoot}');

  await processTemplateArgs(Config.templateRoot, libArgs, tArgs); // args);

  // if ( // _options.wasParsed('help') ||
  //     libArgs.contains('-h') || libArgs.contains('--help')) {
  //     print('Library: $pkg');
  //   // printDartrixUsage();
  // }

  // initPluginTemplates(pkg);

  Config.templateRoot = path.normalize(templates[template]['root']);
  // Config.prodLogger.v('saving Config.templateRoot = ${Config.templateRoot}');

  // await spawnPluginFromPackage(
  //     spawnCallback, externalOnDone, pkg, [template, ...?tArgs]);
}

void processTemplateArgs(
    String dir, List<String> libArgs, List<String> tArgs) async {
  // Config.debugLogger.v('processTemplateArgs: $dir, $libArgs $tArgs');

  // 1. construct arg parser from yaml file
  // next: construct arg parser from yaml file

  var template = path.basename(dir);
  // Config.logger.v('processArgs template: $template');

  var yaml = getTemplateConfig(dir); // templates['dart_cmdsuite']['root']);
  // + '/templates/' + template);
  // Config.logger.i('yaml: ${yaml.params}');

  var _argParser = ArgParser(allowTrailingOptions: true, usageLineLength: 100);
  yaml.params.forEach((param) {
    // Config.logger.i('param: $param');
    if (param.typeHelp == 'bool') {
      _argParser.addFlag(param.name,
          abbr: param.abbr,
          help: param.help,
          defaultsTo: (param.defaultsTo == 'true') ? true : false);
    } else {
      _argParser.addOption(param.name,
          abbr: param.abbr,
          valueHelp: param.typeHelp,
          help: param.docstring,
          //+ param?.help ,
          defaultsTo: param.defaultsTo);
    }
  });
  // always add --help
  _argParser.addFlag('help', abbr: 'h', defaultsTo: false, negatable: false);

  if (Config.debug) {
    Config.ppLogger.i('Params for template $template: ${_argParser.options}');
  }

  // print(_argParser.usage);
  // exit(0);

  // first arg is 'dartrix', omit
  // var myargs = _options.rest.sublist(1);
  // print('tArgs: $tArgs');
  var myoptions;
  try {
    myoptions = _argParser.parse(tArgs);
  } catch (e) {
    Config.ppLogger.e(e);
    exit(0);
  }
  // print('myoptions: ${myoptions.options}');
  // print('args: ${myoptions.arguments}');

  if (myoptions.wasParsed('help')) {
    // printUsage(_argParser);
    print('\nTemplate \'$template\' options:');
    print(_argParser.usage);
    if (yaml.note != null) {
      print('\nNote: ${yaml.note}');
    }
    exit(0);
  }

  // now merge user passed args with default data map
  // print('MERGE user options');

  tData['segmap'].forEach((seg, v) {
    tData[seg.toLowerCase()] = v;
  });

  tData['domain'] = tData['segmap']['DOMAIN'];
  tData['rdomain'] = tData['domain'].split('.').reversed.join('.');
  // tData['pkgpath'] = tData['rdomain'].replaceAll('.', '/');
  // tData['segmap']['PKGPATH'] = tData['pkgpath'];
  tData['segmap']['ORG'] = tData['ORG'];

  myoptions.options.forEach((option) {
    // print('option: ${option} = ${myoptions[option]}');
    // print('params rtt: ${yaml.params.runtimeType}');
    var param;
    try {
      param = yaml.params.firstWhere((param) {
        return param.name == option;
      });
      // print('yaml: ${param.name}');
      if (param.hook != null) {
        switch (param.hook) {
          case 'java-pkg':
            javaPkgHook(myoptions[option]);
            break;
          default:
        }
      } else {
        if (param.seg != null) {
          tData['segmap'][param.seg] = myoptions[option];
          tData[option] = myoptions[option];
        } else {
          tData[option] = myoptions[option];
        }
      }
      // if (params['segment'] == null) {
      // } else {
      // }
    } catch (e) {
      // this will happen for e.g. the help option that was not specified in
      // the yaml file.
      // print(e);
    }
  });
}

void javaPkgHook(String pkg) {
  tData['segmap']['PKGPATH'] = pkg.replaceAll('.', '/');
  tData['pkg'] = pkg;
}
