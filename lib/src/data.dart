import 'dart:io';

import 'package:args/args.dart';
import 'package:process_run/which.dart';
import 'package:safe_config/safe_config.dart';

// import 'package:args/args.dart';
// import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/annotations.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/yaml.dart';

// var _log = Logger('data');

// tlib spec: map with properties:
// name, version, docstring, rootUri (= pkg root, not :package root)
// scope: builtin, here, home (user?), local, sys, pub.dev


/// Builtin templates.
Map<String, String> builtinTemplates = {};

Map xData; // external data

// String domain2RDomPath(String domain) {
// }

// void mergeUserOptions() {
//   if (Config.options['root'] != Config.argParser.getDefault('root')) {
//     tData['seg']['ROOT'] = Config.options['root'];
//   }
//   if (Config.options['domain'] != Config.argParser.getDefault('domain')) {
//     // user specified domain
//     tData['seg']['RDOMAINPATH'] =
//         Config.options['domain'].split('.').reversed.join('/');
//   }
//   if (Config.options['class'] != Config.argParser.getDefault('class')) {
//     tData['seg']['CLASS'] = Config.options['class'];
//   }
// }

Map _mergeExternalData(Map _data, Map xData) {
  xData.forEach((k, v) {
    if (_data[k] == null) {
      _data[k] = v;
    } else {
      if (_data[k] is Map) {
        if (v is Map) {
          _data[k] = _mergeExternalData(_data[k], v);
        } else {
          _data[k] = v;
        }
      } else {
        _data[k] = v;
      }
    }
  });
  return _data;
}

Map mergeExternalData(Map _data, Map xData) {
  tData = _mergeExternalData(_data, xData);
  if (xData['root'] != null) {
    tData['seg']['ROOTPATH'] = xData['root'];
  }
  if (xData['domain'] != null) {
    tData['seg']['RDOMAINPATH'] =
        xData['domain'].split('.').reversed.join('/');
  }
  if (xData['class'] != null) {
    tData['seg']['CLASS'] = xData['class'];
  }

  // now set global var
  tData = _data;
  return tData;
}

// FIXME: find best way to get these values.
// They're for android/local.properties
// print("resolvedExecutable: ${Platform.resolvedExecutable}");
var androidExecutable = whichSync('android');
// print("android exe: $androidExecutable");
var android_sdk =
    path.joinAll(path.split(androidExecutable)..removeLast()..removeLast());

var flutterExecutable = whichSync('flutter');
// print("flutter exe: $flutterExecutable");
var flutter_sdk =
    path.joinAll(path.split(flutterExecutable)..removeLast()..removeLast());

// this should be called at startup
// void initSeg(ArgResults options) {
//   tData['seg']['PLATFORM'] = Platform.operatingSystem;
//   tData['seg']['PKG'] = Config.options['package'];
//   tData['seg']['CLASS'] = Config.options['class'];
//   tData['seg']['RDOMAINPATH'] = tData['rdomain'].replaceAll(Config.hereDir, '/');
//   if (Config.options['relative-root'] == null) {
//     tData['seg']['ROOT'] = './';
//   } else {
//     tData['seg']['ROOT'] = Config.options['ROOT'];
//   }
// }

// void dartPkgHook(String pkg) {
//   tData['seg']['DPKG'] = pkg.replaceAll(Config.hereDir, '/');
//   tData['package']['dart'] = pkg;
// }

// void javaPkgHook(String pkg) {
//   tData['rdomain'] = pkg;
//   tData['seg']['RDOMAIN'] = tData['rdomain'].replaceAll(Config.hereDir, '/');
//   tData['package']['java'] = pkg;
// }

/// add parameters to argparser
void processParam(ArgParser _argParser, Param param) {
  // print('''198df396-bdb2-486e-b2e3-b7b5bef56219: user param:  ${param.name}''');
  if (param.private) {
    // do not expose private params
  // } else if (param.typeHint == '_here') {
  //   _argParser.addFlag(param.name,
  //     abbr: param.abbr,
  //     help: param.help,
  //     hide: param.hidden ?? false,
  //     negatable: param.negatable ?? true,
  //     defaultsTo: param.defaultsTo ?? false);// == 'true') ? true : false);
  } else if (param.typeHint == 'bool') {
    _argParser.addFlag(param.name,
      abbr: param.abbr,
      help: param.help,
      hide: param.hidden ?? false,
      negatable: param.negatable ?? true,
      defaultsTo: (param.defaultsTo == 'true') ? true : false);
  } else if (param.id == 'package') {
    _argParser.addOption(param.name,
      abbr: param.abbr,
      valueHelp: param.typeHint,
      help: param.help,
      hide: param.hidden ?? false,
      defaultsTo: param.defaultsTo ?? '');
    // } else if (yaml.generic.index != null && (param.typeHint == Config.genericIndex)) {
    //   _argParser.addOption(param.name,
    //     abbr: param.abbr,
    //     valueHelp: (param.typeHint == '_out')
    //     ? 'path'
    //     : (param.typeHint == Config.genericIndex)
    //     ? 'String'
    //     : param.typeHint,
    //     // allowed: allowedVals,
    //     help: (param.typeHint == '_out')
    //     ? 'Output path relative to ./'
    //     : param.docstring,
    //     defaultsTo: param.defaultsTo + '_<' + Config.genericIndex + '>');
  } else {
    _argParser.addOption(param.name,
      abbr: param.abbr,
      // valueHelp: param.docstring,
      valueHelp: param.typeHint,
      // valueHelp: (param.typeHint == '_out')
      // ? param.docstring : param.typeHint,
      // help: (param.typeHint == '_out')
      // ? 'Output path relative to ./'
      // : param.docstring,
      help: param.help,
      defaultsTo: param.defaultsTo ?? '');
  }
}

// void processSysParam(ArgParser _argParser, SysParam param) {
//   print('''9562702f-b8a1-4fc4-b3fe-813c26c26149: sys param: ${param.param}''');
//   var sysP = sysParams[param.param];
//   print('''8be367af-a775-496d-b863-ab98c02661b5:  sysP: ${sysP.name}''');
//   if (param.private) {
//     print('''fb830524-b7ca-4e34-89c6-3f26e8e935a2:  omitting private: ${param.param}''');
//     // do not expose private params
//   } else if (sysP.typeHint == '_here') {
//     _argParser.addFlag(param.name,
//       abbr: param.abbr ?? sysP.abbr,
//       help: sysP.help,
//       hide: param.hidden ?? sysP.hidden ?? false,
//       negatable: sysP.negatable ?? true,
//       defaultsTo: param.defaultsTo ?? sysP.defaultsTo ?? false);
//   } else if (sysP.typeHint == 'bool') {
//     _argParser.addFlag(param.param,
//       abbr: param.abbr ?? sysP.abbr,
//       help: sysP.help,
//       hide: param.hidden ?? sysP.hidden ?? false,
//       negatable: sysP.negatable ?? false,
//       defaultsTo: (param.defaultsTo == 'true') ? true
//       : false);
//       // defaultsTo: param.defaultsTo ?? sysP.defaultsTo);
//     // } else if (yaml.generic.index != null && (param.typeHint == Config.genericIndex)) {
//     //   _argParser.addOption(param.name,
//     //     abbr: param.abbr,
//     //     valueHelp: (param.typeHint == '_out')
//     //     ? 'path'
//     //     : (param.typeHint == Config.genericIndex)
//     //     ? 'String'
//     //     : param.typeHint,
//     //     // allowed: allowedVals,
//     //     help: (param.typeHint == '_out')
//     //     ? 'Output path relative to ./'
//     //     : param.docstring,
//     //     defaultsTo: param.defaultsTo + '_<' + Config.genericIndex + '>');
//   } else {
//     print('''01943703-da53-423c-8c6c-7fe01af4254c: adding p: ${param.param}''');
//     _argParser.addOption(param.name ?? sysP.name,
//       abbr: param.abbr ?? sysP.abbr,
//       valueHelp: sysP.typeHint, // param.typeHint ?? sysP.typeHint,
//       // help: (param.typeHint == '_out')
//       // ? 'Output path relative to ./'
//       // : param.docstring,
//       help: sysP.help,
//       defaultsTo: param.defaultsTo ?? sysP.defaultsTo);
//   }
// }

/// User-specified sys params override default sys params
/// 'forget' the param field
List _resolveSysParams(List<SysParam> _sysParams) {
  List result = [];
  _sysParams.forEach((sys) {
      SysParam defaultParam = sysParams[sys.id];
      // now override fields
      defaultParam.id = sys.id;
      defaultParam.name = sys.name ?? defaultParam.name;
      defaultParam.abbr = sys.abbr ?? defaultParam.abbr;
      defaultParam.typeHint = sys.typeHint ?? defaultParam.typeHint;
      defaultParam.defaultsTo = sys.defaultsTo ?? defaultParam.defaultsTo;
      defaultParam.private = sys.private ?? defaultParam.private;
      result.add(defaultParam);
  });
  return result;
}

void processOption(ArgResults myoptions, String option) {
  print('''97ebea73-d564-483a-86e4-6759fdb17780:  processOption $option''');
}

//FIXME: put this in template.dart?
void setTemplateArgs(
  String templateRoot, List<String> libArgs, List<String> tArgs) async {
  // Config.debugLogger.v('setTemplateArgs: $templateRoot, $libArgs $tArgs');

  // debug.debugData({});
  // 1. construct arg parser from yaml file
  // next: construct arg parser from yaml file

  var template = path.basename(templateRoot);
  // Config.logger.v('processArgs template: $template');

  // ~/.dart.d/.dart_tool/package_config.json
  var yaml = getTemplateYaml(templateRoot);
  // + '/templates/' + template);
  // Config.logger.i('yaml: ${yaml.params}');

  var _argParser = ArgParser(allowTrailingOptions: true, usageLineLength: 100);

  var allowedVals;
  var genericIndexParam;
  var replaceString;

  if (yaml.generic != null) {

    @block("Analyze params for generic templates and add to arg parser.")
    var _prepGeneric = () {
      Config.generic = true;
      Config.genericIndex = yaml.generic.index.name;
      Config.genericRewrite = yaml.generic.rewrite;
      replaceString = '_<' + Config.genericIndex + '>';

      var indexVals = Directory(Config.templateRoot).listSync(recursive: true);
      //FIXME: memoize these so generator need not read again
      indexVals.removeWhere((f) => f.path.endsWith('~'));
      indexVals.removeWhere((f) => f.path.contains('/.'));
      indexVals.removeWhere((f) => f.path.endsWith(Config.genericIndex));
      indexVals.retainWhere((f) => f is Directory);

      // print('indexVals $indexVals');
      allowedVals = indexVals.map((dir) {
          var tpath = dir.path.replaceFirst(Config.templateRoot + '/', '');
          return path.split(tpath)[0];
      }).toSet();
      // print('allowedVals: $allowedVals');

      _argParser.addOption(Config.genericIndex,
        abbr: yaml.generic.index.abbr,
        allowed: allowedVals,
        help: yaml.generic.index.typeHint,
        defaultsTo: yaml.generic.index.defaultsTo);
      // defaultsTo: param.defaultsTo + '_<' + Config.genericIndex + '>');
    };
    _prepGeneric();
  }

  List _sysParams = _resolveSysParams(yaml.params.sys);
  List allParams = [];
  if (yaml.params.user != null) {
    allParams.addAll(yaml.params.user);
  }
  if (_sysParams != null) {
    allParams.addAll(_sysParams);
  }
  allParams.forEach((param) {
      processParam(_argParser, param);
  });

  // always add --help
  _argParser.addFlag('help', defaultsTo: false, negatable: false,
  help: 'Print this message');

  if (Config.debug) {
    Config.ppLogger.i('Params for template $template: ${_argParser.options}');
  }

  var myoptions;
  @block("Parse the args")
  var _parseOptions = () {
    try {
      myoptions = _argParser.parse(tArgs);
    } catch (e) {
      print('''ff2ac114-1a10-454a-a9c4-657e74411d98:  ''');
      Config.ppLogger.e(e);
      exit(0);
    }
  };
  _parseOptions();
  // print('myoptions: ${myoptions.options}');
  // print('args: ${myoptions.arguments}');

  if (yaml.generic != null) {
    Config.genericSelection = myoptions[Config.genericIndex];
  }

  if (myoptions.options.contains('here') && myoptions['here'] == true) {
    Config.here = true;
  }
  // print('config.here: ${Config.here}');

  if (myoptions.wasParsed('help')) {
    // printUsage(_argParser);
    print('\nTemplate \'$template\': ${yaml.description}');
    print('Options:');
    print(_argParser.usage);
    if (yaml.note != null) {
      print('\nNote: ${yaml.note}');
    }
    exit(0);
  }

  tData['seg']['JPKG'] = tData['rdomain'].replaceAll(Config.hereDir, '/');
  tData['seg']['_NS'] = tData['seg']['JPKG'];
  tData['seg']['_NSX'] = tData['subdomain'];
  // tData['seg']['ORG'] = tData['ORG'];

  if (yaml.meta != null) {
    Config.meta = yaml.meta.meta;
  }

  // print('''364bb527-b92d-4951-98eb-3e3b78d8447c:  debug options:''');
  // if (debug.debug) debug.debugOptions();

  @block("Process each option, updating template data map")
  var _processEachOption = () {
    myoptions.options.forEach((option) {
        // print('''3728ec79-30ee-4fac-abb5-da49998ef2fc: option: ${option} = ${myoptions[option]}''');
        // print('params rtt: ${yaml.params.runtimeType}');

        @block('''Find the yaml param matching the option. It will be used to
        control processing.''')
        var param;
        if (option == Config.genericIndex) {
          param = yaml.generic.index;
        } else {
          try {
            // param = yaml.params.user.firstWhere((param) {
            param = allParams.firstWhere((param) {
                return param.name == option;
            });
          } catch (e) {
            if (option == 'help') return; // expected
            if (option == 'force') return; // expected
            Config.ppLogger.e(
              '''e28d8a20-2010-4d0c-8675-31c571d8760c: option: $option
              $e''');
            // Config.ppLogger.e(e);
            return;
          }
        }

        // processOption(myoptions, option);

        if (param.typeHint == '_plugin_name') {
          tData['_plugin_name'] = myoptions[option];
        }

        if (param.name == Config.genericIndex) {
          // print('''f083e6f9-d58e-449a-b86f-cc0b15bd378b: opt genericIndex: ${param.name}''');
          tData[param.name] = myoptions[option];
          tData[Config.genericIndex] = myoptions[option]
          .replaceAll(replaceString, '_' + Config.genericSelection);
          tData[option] = tData[Config.genericIndex];
        } else if (param.name == Config.genericRewrite) {
          // print('''e3645586-5bb3-4190-a836-011ec064a913:  rewrite ${Config.genericRewrite}''');
          Config.genericRewrite = myoptions[option]
          .replaceAll(Config.genericIndex, Config.genericSelection);
          tData[option] = myoptions[option];
          // now check for reserved param types
        } else if ((param.defaultsTo != null)
          && (param.defaultsTo.contains('<<'))) {
          print('''1a8dbcdd-62dd-4e38-8e8e-f049311568cb:  XXXXXXXXXXXXXXXX''');
          tData[param.name] = myoptions[option];
          tData['_out'] = myoptions[option];
        } else if (param.seg != null) {
          tData[param.seg.toLowerCase()] = myoptions[option];
          tData['seg'][param.seg.toUpperCase()] = myoptions[option];
          tData[option] = myoptions[option];
          if (Config.meta != null) {
            tData['seg']['_META'].add(param.seg);
          }
        } else {
          // print('''8d6fe169-bb1d-41e3-91f0-a0348d138b40:  ELSE: $option''');
          tData[option] = myoptions[option];
        }

        if (param is SysParam) {
          switch (param.id) {
            case 'out':
            if (param.defaultsTo != null) {
              if (param.defaultsTo.contains('<<')) {
                // if (param.defaultsTo == myoptions[param.name]) {
                  // no user override
                  RegExp regExp = RegExp(r'<<([^>]*)>>');
                  var match = regExp.firstMatch(param.defaultsTo).group(1);
                  print('''7709702d-a6ad-4fd5-87d4-071f5045e2a1:  match: ${match}''');
                  var def = myoptions[match];
                  var defaultVal = myoptions[option].replaceFirst('<<' + match + '>>', def);
                  // var defaultVal = param.defaultsTo.replaceFirst('<<' + match + '>>', def);
                  print('''8b32734b-0e4f-4906-ba64-0a6ccba0a910:  default: ${defaultVal}''');
                  tData[param.name] = defaultVal;
                  tData['dartrix']['out'] = defaultVal;
                // } else {
                //   // user passed defaultsTo, overriding default << >>
                //   tData[param.name] = myoptions[option];
                //   tData['dartrix']['out'] = myoptions[option];
                // }
              } else {
                tData[param.name] = myoptions[option];
                tData['dartrix']['out'] = myoptions[option];
              }
            } else {
              tData[param.name] = './';
              tData['dartrix']['out'] = './';
            }
            break;
            case 'package': // dart package name
            tData['dartrix']['package']
            = (myoptions[option] == '') ? false : myoptions[option];
            tData['seg']['_PACKAGE']
            = (myoptions[option] == '')
            ? false
            : myoptions[option];
            break;
            case 'ns':
            print('''96e446ff-2d9e-464a-8938-1d3a75ce774f:  NS''');
            tData['dartrix']['ns'] = myoptions[option];
            tData['seg']['_NS'] = tData['dartrix']['ns'].replaceAll('.', '/');
            tData['dartrix']['rns'] = tData['dartrix']['ns']
            .split('.').reversed.join('.');
            tData['seg']['_RNS'] = tData['dartrix']['rns'].replaceAll('.', '/');
            break;
            // } else if (param.typeHint == '_here') {
            //   if (myoptions[option]) { // --here = true
            //     tData['seg']['TEMPLATES'] = '.templates';
            //   } else {
            //     tData['seg']['TEMPLATES'] = 'templates';
            //   }
            case 'nsx': // ns extension
            print('''bc14bbce-bdee-4959-9274-8da7dd8c0163:  NSX''');
            tData['dartrix']['nsx']
            = (myoptions[option] == '') ? false : myoptions[option];
            tData['seg']['_NSX']
            = (myoptions[option] == '')
            ? false
            : myoptions[option].replaceAll('.', '/');
            break;
            case '_name':
            tData[param.name] = myoptions[option];
            tData['dartrix']['name'] = myoptions[option];
            break;
            // } else if (param.typeHint == '_dart_package') {
//   tData['seg']['DPKG'] = pkg.replaceAll(Config.hereDir, '/');
//   tData['package']['dart'] = pkg;

            //   // tData['seg']['DPKG'] = myoptions[option](Config.hereDir, '/');
            //   tData['package']['dart'] = myoptions[option];
            //   if (param.seg != null) {
            //     tData['seg'][param.seg] = myoptions[option];
            //   }
            default:
            print('''fc52af93-79a3-4ffe-8268-b5be7f7437de:  DEFAULT''');
          }
        }
    });
  }; _processEachOption();

  @block("Now process private params.")
  var _processPrivateParams = () {
    allParams.forEach((param) {
        if (param.private) {
          print('''673bc742-8056-4033-ad6a-0534e490674d:  PRIVATE: ${param.name}''');
        }
  });

  };  _processPrivateParams();
  // debug.debugData({});
}

Map tData = {
  'dartrix': {'out': './', 'force': false},
  'now': '${DateTime.now()}',
  'today':
      '${DateTime.now().year}, ${DateTime.now().month}, ${DateTime.now().day}',
  'version': {
    'android': {
      'compile_sdk': '28',
      'min_sdk': '16',
      'target_sdk': '28',
      // androidx.test:runner:1.1.1
      // androidx.test.espresso:espresso-core:3.1.1'
    },
    'app': '0.1.0',
    'args': '^1.6.0',
    'cupertino_icons': '\'^0.1.3\'',
    'dartrix' : Config.appVersion,
    'e2e': '^0.2.0',
    'flutter': '\'>=1.12.8 <2.0.0\'',
    'gradle': '3.5.0',
    'junit': '4.12',
    'kotlin': '1.3.50',
    'logger': '^0.8.3',
    'meta': '^1.1.8',
    'mockito': '^4.1.1',
    'package': '0.0.1',
    'path': '^1.6.4',
    'pedantic': '^1.8.0',
    'platform_detect': '^1.4.0',
    'plugin_platform_interface': '^1.0.2',
    'safe_config': '^2.0.2',
    'sdk': '\'>=2.1.0 <3.0.0\'',
    'test': '^1.9.4' // for compatibility with flutter_test
  },
  'description': {
    'adapter': 'A Flutter plugin adapter component.',
    'android': 'A Flutter Plugin implementation for the Android platform.',
    'app': 'A Flutter application.',
    'component': 'A Flutter Plugin.',
    'demo': 'Demo using a Flutter Plugin.',
    'ios': 'A Flutter Plugin implementation for the iOS platform.',
    'linux': 'A Flutter Plugin implementation for the Linux platform.',
    'macos': 'A Flutter Plugin implementation for the MacOS platform.',
    'package': 'Package description.',
    'web': 'A Flutter Plugin implementation for the web platform.',
    'windows': 'A Flutter Plugin implementation for the Windows platform.',
  },
  'platform': null,
  'domain': 'example.org',
  'rdomain': 'org.example',
  'subdomain': 'hello',
  // 'pkg': 'org.example',
  'jpkg': 'org.example',
  'package': {
    // 'dart' : Config.options['package'],
    // 'java' : javaPackage
  },
  // 'plugin-class' : pluginClass,
  'sdk': {
    'android': android_sdk,
    'dart': '\'>=2.1.0 <3.0.0\'',
    'flutter': flutter_sdk,
  },
  // seg keys are segments used in your template dir structure.
  // Vals are default output values. Use cmd args to expose to user.
  // 'out': './',
  'seg': {
    // keys are segment placeholders in path templates
    'ROOT': '/',
    // 'HOME': Config.home,
    // 'CWD': '.', // DO NOT CANONICALIZE
    'SYSTEMP': Directory.systemTemp.path,
    'DOT': '.', // rewrite DOTfoo as .foo
    // 'DOTDIR_D': '',
    // 'DOMAIN': 'example/org',
    // 'RDOMAIN': 'org/example',
    // 'SUBDOMAIN': 'hello',
    'CLASS': 'Hello',
    'JPKG': 'org/example',
    // 'ORG' : 'org/example',  // reverse-domain notation
    'DEPT': 'hello', // forms part of package url, org.example.hello
    // _META: list of segs to rewrite even in meta mode
    '_META': [],
  }
};
