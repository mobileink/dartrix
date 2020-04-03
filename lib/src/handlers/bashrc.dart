// import 'dart:io';

import 'package:args/args.dart';
// import 'package:logger/logger.dart';
// import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/generator.dart';

import 'package:dartrix/src/builtins.dart';

void printUsage(ArgParser argParser) async {
  print('\nTemplate \'bashrc\' options:');
  print(argParser.usage);
}

void handleBashrc(String dir, List<String> tArgs) async {
  if (Config.debug) {
    Config.debugLogger.i('handleBashrc, subargs $tArgs');
  }

  // 1. construct arg parser from yaml file

  // // next: construct arg parser from yaml file
  // var yaml = getTemplateYaml(dir); // templates['bashrc']['root']);
  // // + '/templates/' + template);
  // // Config.logger.i('yaml: ${yaml.params}');

  // var _argParser = ArgParser(allowTrailingOptions: true, usageLineLength: 100);
  // yaml.params.forEach((param) {
  //   // Config.logger.i('param: $param');
  //   if (param.typeHelp == 'bool') {
  //     _argParser.addFlag(param.name,
  //         abbr: param.abbr,
  //         help: param.help,
  //         defaultsTo: (param.defaultsTo == 'true') ? true : false);
  //   } else {
  //     _argParser.addOption(param.name,
  //         abbr: param.abbr,
  //         valueHelp: param.typeHelp,
  //         help: param.docstring + ' ' + param.help,
  //         defaultsTo: param.defaultsTo);
  //   }
  // });
  // // always add --help
  // _argParser.addFlag('help', abbr: 'h', defaultsTo: false, negatable: false);

  // if (Config.debug) {
  //   Config.debugLogger.i('Params for template bashrc: ${_argParser.options}');
  // }

  // // print(_argParser.usage);
  // // exit(0);

  // // first arg is 'dartrix', omit
  // // var myargs = _options.rest.sublist(1);
  // // print('tArgs: $tArgs');
  // var myoptions;
  // try {
  //   myoptions = _argParser.parse(tArgs);
  // } catch (e) {
  //   Config.prodLogger.e(e);
  //   exit(0);
  // }
  // // print('myoptions: ${myoptions.options}');
  // // print('args: ${myoptions.arguments}');

  // if (myoptions.wasParsed('help')) {
  //   printUsage(_argParser);
  //   exit(0);
  // }

  // // now merge user passed args with default data map
  // // print('MERGE user options');
  // myoptions.options.forEach((option) {
  //   // print('option: ${option} = ${myoptions[option]}');
  //   // print('params rtt: ${yaml.params.runtimeType}');
  //   var param;
  //   try {
  //     param = yaml.params.firstWhere((param) {
  //       return param.name == option;
  //     });
  //     // print('yaml: ${param.name}');
  //     if (param.seg != null) {
  //       tData['seg'][param.seg] = myoptions[option];
  //     } else {
  //       tData[option] = myoptions[option];
  //     }
  //     // if (params['segment'] == null) {
  //     // } else {
  //     // }
  //   } catch (e) {
  //     // this will happen for e.g. the help option that was not specified in
  //     // the yaml file.
  //     // print(e);
  //   }
  // });

  // tData['prefix'] = myoptions['prefix'];
  // tData['enable-asserts'] = myoptions['enable-asserts']? ' --enable-asserts' : '';

  // tData['seg']['bashrc'] = myoptions['name'];

  // var dcf = myoptions['dartrix-config-home'];
  // print('dartrix-config-home: ${dcf}');
  // if (path.isAbsolute(dcf)) {
  //   tData['seg']['HOME'] = dcf;
  // } else {
  //   // tData['seg']['HOME'] = tData['seg']['HOME'] + '/' + dcf;
  //   tData['seg']['HOME'] = Directory.current.path + '/' + dcf;
  // }

  // tData['seg']['DOTDIR_D'] = myoptions['config-dir'];

  await processTemplate();
}
