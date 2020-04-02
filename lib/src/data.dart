import 'dart:io';

import 'package:args/args.dart';
import 'package:process_run/which.dart';

// import 'package:args/args.dart';
// import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

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
//     tData['segmap']['ROOT'] = Config.options['root'];
//   }
//   if (Config.options['domain'] != Config.argParser.getDefault('domain')) {
//     // user specified domain
//     tData['segmap']['RDOMAINPATH'] =
//         Config.options['domain'].split('.').reversed.join('/');
//   }
//   if (Config.options['class'] != Config.argParser.getDefault('class')) {
//     tData['segmap']['CLASS'] = Config.options['class'];
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
    tData['segmap']['ROOTPATH'] = xData['root'];
  }
  if (xData['domain'] != null) {
    tData['segmap']['RDOMAINPATH'] =
        xData['domain'].split('.').reversed.join('/');
  }
  if (xData['class'] != null) {
    tData['segmap']['CLASS'] = xData['class'];
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
// void initSegmap(ArgResults options) {
//   tData['segmap']['PLATFORM'] = Platform.operatingSystem;
//   tData['segmap']['PKG'] = Config.options['package'];
//   tData['segmap']['CLASS'] = Config.options['class'];
//   tData['segmap']['RDOMAINPATH'] = tData['rdomain'].replaceAll(Config.hereDir, '/');
//   if (Config.options['relative-root'] == null) {
//     tData['segmap']['ROOT'] = './';
//   } else {
//     tData['segmap']['ROOT'] = Config.options['ROOT'];
//   }
// }

void dartPkgHook(String pkg) {
  tData['segmap']['DPKG'] = pkg.replaceAll(Config.hereDir, '/');
  tData['package']['dart'] = pkg;
}

void javaPkgHook(String pkg) {
  tData['rdomain'] = pkg;
  tData['segmap']['RDOMAIN'] = tData['rdomain'].replaceAll(Config.hereDir, '/');
  tData['package']['java'] = pkg;
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
  yaml.params.forEach((param) {
    // Config.logger.i('param: ${param.name}');
    if (param.private) {
      // do not expose private params
    } else if (param.type == 'bool') {
      _argParser.addFlag(param.name,
        abbr: param.abbr,
        help: param.help,
        hide: param.hidden ?? false,
        negatable: param.negatable ?? true,
        defaultsTo: (param.defaultsTo == 'true') ? true : false);
    } else {
      // print('${param.type}');
      _argParser.addOption(param.name,
        abbr: param.abbr,
        valueHelp: (param.type == '_out_prefix') ? 'path' : param.type,
        help: (param.type == '_out_prefix')
        ? 'Output path relative to ./'
        : param.docstring,
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

  if (yaml.generic != null) {
    Config.generic = true;
    var indexParam = yaml.params.singleWhere((p) => p.name == yaml.generic);
    print('generic indexParam: $indexParam');
    Config.genericIndex = '_' + myoptions[indexParam.name];
    print('genericIndex: ${Config.genericIndex}');
  }

  if (myoptions.options.contains('here') && myoptions['here'] == true) {
    Config.here = true;
  }
  print('config.here: ${Config.here}');

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

  // if (myoptions.wasParsed('domain')) {
  //   print('uuuuuuuuuuuuuuuu');
  //   print(myoptions['domain']);
  // }
  // now merge user passed args with default data map
  // print('MERGE user options');

  // Set defaults
  // tData['segmap'].forEach((seg, v) {
  //   tData[seg.toLowerCase()] = v;
  // });

  // print('subdom: ${tData["segmap"]["SUBDOMAIN"]}');


  tData['segmap']['JPKG'] = tData['rdomain'].replaceAll(Config.hereDir, '/');
  tData['segmap']['RDOMAIN'] = tData['segmap']['JPKG'];
  tData['segmap']['SUBDOMAIN'] = tData['subdomain'];
  tData['segmap']['ORG'] = tData['ORG'];

  if (yaml.meta != null) {
    Config.meta = yaml.meta.meta;
  }

  // if (yaml.meta == true) {
  //   Config.meta = true;
  //   tData['segmap']['YAML'] = '.yaml';
  // }

  // print('RDOM2: ${tData["segmap"]["RDOMAIN"]}');

  // print('subdom2: ${tData["segmap"]["SUBDOMAIN"]}');


  // Override with user args
  myoptions.options.forEach((option) {
    // print('option: ${option} = ${myoptions[option]}');
    // print('params rtt: ${yaml.params.runtimeType}');
    var param;
    // get the yaml param matching the option

    try {
      param = yaml.params.firstWhere((param) {
        return param.name == option;
      });
    } catch (e) {
      // this will happen for e.g. the help option that was not specified in
      // the yaml file.
      if (option == 'help') return;
      Config.ppLogger.e('option: $option');
      Config.ppLogger.e(e);
      return;
    }

    if (param.type == '_plugin_name') {
      tData['_plugin_name'] = myoptions[option];
    }

    if (param.type == '_template_name') {
      tData['_template_name'] = myoptions[option];
    }

    // print('yaml: ${param.name} : ${param.defaultsTo}');
    if (param.hook != null) {
      switch (param.hook) {
        case 'dpkg-hook':
          dartPkgHook(myoptions[option]);
          break;
        case 'jpkg':
        case 'java-pkg':
          javaPkgHook(myoptions[option]);
          tData[option] = myoptions[option];
          break;
        default:
          Config.prodLogger.w('Unknown param hook: ${param.hook}');
      }
    } else if (param.type == '_out_prefix') {
      tData['_out_prefix'] = myoptions[option];
    } else if (param.type == '_dart_package') {
      // tData['segmap']['DPKG'] = myoptions[option](Config.hereDir, '/');
      tData['package']['dart'] = myoptions[option];
      if (param.seg != null) {
        tData['segmap'][param.seg] = myoptions[option];
      }
    } else {
      if (param.seg == null) {
        tData[option] = myoptions[option];
        switch (option) {
          case 'domain':
            tData['domain'] = myoptions[option];
            tData['segmap']['DOMAIN'] = myoptions[option].replaceAll(Config.hereDir, '/');
            tData['rdomain'] = tData['domain'].split('.').reversed.join('.');
            tData['segmap']['RDOMAIN'] = tData['rdomain'].replaceAll('.', '/');
            break;
          case 'subdomain':
            tData['subdomain'] = myoptions[option];
            tData['segmap']['SUBDOMAIN'] =
                myoptions[option].replaceAll('.', '/');
            break;
            case 'here':
            if (myoptions[option]) {
              tData['segmap']['TEMPLATES'] = '.templates';
            } else {
              tData['segmap']['TEMPLATES'] = 'templates';
            }
            break;
          default:
        }
      } else {
        // seg params
        if (param.seg == 'DOMAIN') {
          tData['domain'] = myoptions[option];
          tData['rdomain'] = tData['domain'].split('.').reversed.join('.');
          tData['segmap']['DOMAIN'] = tData['domain'].replaceAll('.', '/');
          tData['segmap']['RDOMAIN'] = tData['rdomain'].replaceAll('.', '/');
        } else {
          tData[param.seg.toLowerCase()] = myoptions[option];
          tData['segmap'][param.seg.toUpperCase()] = myoptions[option];
          tData[option] = myoptions[option];
          if (Config.meta != null) {
            tData['segmap']['_META'].add(param.seg);
          }
        }
      }
    }
    // print('looping');
  });
}

Map tData = {
  'dartrix': {'force': false},
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
  // segmap keys are segments used in your template dir structure.
  // Vals are default output values. Use cmd args to expose to user.
  'out': './',
  'segmap': {
    // keys are segment placeholders in path templates
    'ROOT': '/',
    // 'HOME': Config.home,
    // 'CWD': '.', // DO NOT CANONICALIZE
    'SYSTEMP': Directory.systemTemp.path,
    'DOT': '.', // rewrite DOTfoo as .foo
    // 'DOTDIR_D': '',
    'DOMAIN': 'example/org',
    'RDOMAIN': 'org/example',
    'SUBDOMAIN': 'hello',
    'CLASS': 'Hello',
    'JPKG': 'org/example',
    // 'ORG' : 'org/example',  // reverse-domain notation
    'DEPT': 'hello', // forms part of package url, org.example.hello
    // _META: list of segs to rewrite even in meta mode
    '_META': [],
  }
};
