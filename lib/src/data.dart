import 'dart:io';

import 'package:args/args.dart';
import 'package:process_run/which.dart';

// import 'package:args/args.dart';
// import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
// import 'package:dartrix/src/debug.dart' as debug;

// var _log = Logger('data');

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
//   tData['segmap']['RDOMAINPATH'] = tData['rdomain'].replaceAll('.', '/');
//   if (Config.options['relative-root'] == null) {
//     tData['segmap']['ROOT'] = './';
//   } else {
//     tData['segmap']['ROOT'] = Config.options['ROOT'];
//   }
// }

void dartPkgHook(String pkg) {
  tData['segmap']['DPKG'] = pkg.replaceAll('.', '/');
  tData['package']['dart'] = pkg;
}

void javaPkgHook(String pkg) {
  tData['segmap']['JPKG_PATH'] = pkg.replaceAll('.', '/');
  tData['package']['java'] = pkg;
}

void setTemplateArgs(
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
          case 'dpkg-hook':
            dartPkgHook(myoptions[option]);
            break;
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
  'pkg': 'org.example',
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
    'HOME': Config.home,
    'CWD': Directory.current.path,
    'SYSTEMP': Directory.systemTemp.path,
    'DOTFILE': '', // rewrite DOTFILE.foo as .foo
    'DOTDIR_D': '',
    'DOMAIN': 'example.org',
    // 'ORG' : 'org/example',  // reverse-domain notation
    'DEPT': 'hello' // forms part of package url, org.example.hello
  }
};
