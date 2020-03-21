// import 'package:args/args.dart';
// import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
// import 'package:dartrix/src/debug.dart' as debug;

// var _log = Logger('data');

/// Builtin templates.
Map<String, String> builtinTemplates = {};

Map xData; // external data

String rewritePath(String _path) {
  // _log.info('rewritePath: $_path');
  // List<String> segs = domPath.split(path.separator);
  //List<String>
  var segs = _path.split(path.separator);
  var sm = segs.map((seg) {
    // _log.fine('seg: $seg');
    if (tData['segmap'][seg] == null) {
      // no rewrite for full seg, check for partial
      var base = path.basenameWithoutExtension(seg);
      if (tData['segmap'][base] == null) {
        // no rewrite for FOO of FOO.bar, check for BAR of foo.BAR
        var ext = path.extension(seg);
        if (tData['segmap'][ext] == null) {
          return seg;
        } else {
          var rw = base + tData['segmap'][ext];
          return rw;
        }
      } else {
        // e.g. FOO.bar matched FOO
        var rw;
        if (base == 'DOTFILE_D') {
          rw = tData['segmap'][base] + path.extension(seg) + '.d';
        } else {
          rw = tData['segmap'][base] + path.extension(seg);
        }
        return rw;
      }
    } else {
      return tData['segmap'][seg];
    }
  });
  var result = sm.join('/');
  return result;
}

// String domain2RDomPath(String domain) {
// }

void mergeUserOptions() {
  if (Config.options['root'] != Config.argParser.getDefault('root')) {
    tData['segmap']['ROOT'] = Config.options['root'];
  }
  if (Config.options['domain'] != Config.argParser.getDefault('domain')) {
    // user specified domain
    tData['segmap']['RDOMAINPATH'] =
        Config.options['domain'].split('.').reversed.join('/');
  }
  if (Config.options['class'] != Config.argParser.getDefault('class')) {
    tData['segmap']['CLASS'] = Config.options['class'];
  }
}

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

Map tData = {
  'dartrix': {},
  'version': {
    'android': {
      'compile-sdk': '28',
      'min-sdk': '16',
      'target-sdk': '28',
      // androidx.test:runner:1.1.1
      // androidx.test.espresso:espresso-core:3.1.1'
    },
    'cupertino-icons': '\'^0.1.2\'',
    'e2e': '^0.2.0',
    'flutter': '\'>=1.12.8 <2.0.0\'',
    'gradle': '3.5.0',
    'junit': '4.12',
    'kotlin': '1.3.50',
    'meta': '^1.1.8',
    'mockito': '^4.1.1',
    'package': '0.0.1',
    'path': '^1.6.4',
    'pedantic': '^1.8.0',
    'platform-detect': '^1.4.0',
    'plugin-platform-interface': '^1.0.2',
    'sdk': '\'>=2.1.0 <3.0.0\'',
    'test': '^1.9.4' // for compatibility with flutter_test
  },
  'description': {
    'adapter': 'A Flutter plugin adapter component.',
    'component': 'A Flutter Plugin.',
    'demo': 'Demo using a Flutter Plugin.',
    'android': 'A Flutter Plugin implementation for the Android platform.',
    'ios': 'A Flutter Plugin implementation for the iOS platform.',
    'linux': 'A Flutter Plugin implementation for the Linux platform.',
    'macos': 'A Flutter Plugin implementation for the MacOS platform.',
    'web': 'A Flutter Plugin implementation for the web platform.',
    'windows': 'A Flutter Plugin implementation for the Windows platform.',
  },
  'platform': null,
  'domain': {
    // 'default' : 'example.org'
    // 'user'    : 'foo.com'
  },
  'package': {
    // 'dart' : Config.options['package'],
    // 'java' : javaPackage
  },
  // 'plugin-class' : pluginClass,
  'sdk': {
    // 'flutter' : flutter_sdk,
    // 'android' : android_sdk
  },
  // segmap keys are segments used in your template dir structure.
  // Vals are default output values. Use cmd args to expose to user.

  'segmap': {'DOTFILE': '', 'DOTFILE_D': ''} // rewrite DOTFILE.foo as .foo
};
