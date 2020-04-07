import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/annotations.dart';
import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/yaml.dart';

// Path Rewriting

// Built-in rewrite params:

// ROOT : '/'
// HOME : $HOME
// CWD  : Current Working Directory = Directory.current

@defn(returns: "Rewritten path.")
String rewritePath(
  @param("File system path for template component, relative to CWD.")
  String _path)
{
  // Config.ppLogger.i('rewritePath entry: $_path');
  // tData['seg'].forEach((k,v) {
  //     Config.logger.v('seg $k => $v');
  // });
  // List<String> segs = domPath.split(path.separator);

  // debug.debugData({});

  //List<String>
  var thePath = _path.replaceFirst(Directory.current.path + '/', '');
  var segs = thePath.split(path.separator);
  // print('''833396aa-0887-4b9f-9ccb-163f60c70b07:  segs: $segs''');
  var sm = segs.map((seg) {
      // Config.ppLogger.i('seg: $seg');
      if (tData['seg'][seg] == null) {
        // not in segment
        if (seg.endsWith('MUSTACHE')) {
          return seg.replaceAll('MUSTACHE', 'mustache');
        } else {
          // find seg entry whose key is contained in seg
          var key;
          try {
            key = tData['seg'].keys.singleWhere((key) {
                // print('TEST: $key');
                return seg.contains(key);
            });
            // print('MATCH: $seg');
            return seg.replaceAll(key, tData['seg'][key]);
          } catch(e) {
            //print(e);
            // print('nomatch: $seg');
          }
          return seg;

          // no rewrite for full seg, check for partial match
          // var base = path.basenameWithoutExtension(seg);
          // if (tData['seg'][base] == null) {
          //   // no rewrite for FOO of FOO.bar, check for BAR of foo.BAR
          //   var ext = path.extension(seg);
          //   if (tData['seg'][ext] == null) {
          //     return seg;
          //   } else {
          //     var rw = base + tData['seg'][ext];
          //     return rw;
          //   }
          // } else {
          //   // e.g. FOO.bar matched FOO
          //   var rw;
          //   if (base == 'DOTDIR_D') {
          //     rw = tData['seg'][base]; //  + path.extension(seg) + '.d';
          //   } else {
          //     rw = tData['seg'][base] + path.extension(seg);
          //   }
          //   return rw;
          // }
        }
      } else {
        // in seg
        switch (seg) {
          // case 'CWD': return seg; // will be reprocessed below, for metas
          // break;
          // case 'HOME':
          // // Config.ppLogger.v('seg HOME: ${tData["seg"]["HOME"]}');
          // // Config.ppLogger.v('HOME: ${Config.home}');

          // if (tData['seg']['HOME'] != Config.home) {
          //   if (path.isRelative(tData['seg']['HOME'])) {
          //     tData['seg']['HOME'] =
          //     path.canonicalize(Config.home + '/' + tData['seg']['HOME']);
          //   }
          // }
          // // Config.ppLogger.v('rewritten seg HOME: ${tData["seg"]["HOME"]}');
          // return tData['seg'][seg];
          // break;
          default:
          if (Config.meta != null) {
            if (tData['seg']['_META'].contains(seg)) {
              // print('seg: $seg : ${tData["seg"][seg]}');
              return tData['seg'][seg];
            } else {
              return seg;
            }
          } else {
            // print('''5f32b37c-0e5b-4c84-82fa-dd0d3d6beb0d:  seg: ${seg}: ${tData['seg'][seg]}''');
            return (tData['seg'][seg] == false) ? '' : tData['seg'][seg];
          }
        }
      }
  });
  // print('seg._META: ${tData["seg"]["_META"]}');

  // print('''c8eb726a-f9dc-448d-a279-0e1dd82cd4b3:  segs2: $sm''');
  var result = sm.join('/');

  // disallow writing outside of CWD
  if (result.startsWith('/')) {
    Config.ppLogger.w('Templates may not write outside of current working directory and below. Stripping initial \'/\' from output path: $result');
    result = result.substring(1);
  }

  // print('''8d4898e3-3931-4c52-b837-73e068f78ab9:  result $result''');

  // meta: insert path prefix
  if (Config.meta == null) { // not a template or plugin template
    if (tData['_name'] != null) {
      result = tData['_name'] + '/' + result;
    }
    if (tData['dartrix']['out'] != null) {
      result = tData['dartrix']['out'] + '/' + result;
    }
  } else { // ie it's a template or a plugin
   // result = result.replaceFirst('_CWD', '.');
   // if --here
   // print('''b9f13648-ce66-453d-9834-40f41b53402f:  Config.meta: ${Config.meta}''');
   if (Config.meta == 'template') {
     // print('''27206544-17e8-48bb-9b2f-eeb4392d1a07:  Config.replaceParam ${Config.replaceParam}''');
     // print('''27206544-17e8-48bb-9b2f-eeb4392d1a07:  Config.replaceText ${Config.replaceText}''');
     var replace = '<<' + Config.replaceParam  + '>>';
     var t = Config.metaName.replaceFirst(replace, Config.replaceText);
     result = 'templates/' + tData['name'] + '/' + result;
     // result = 'templates/' + Config.genericRewrite + '/' + result;
     // result = 'templates/' + tData[Config.genericIndex] + '/' + result;
   } else if (Config.meta == 'plugin') {
     //FIXME: insert name param with _dartrix
     result = tData['_plugin_name'] + '/' + result;
   }
   result = result.replaceFirst('YAML', '.yaml');
    // result = result.replaceFirst('NAME', 'appname');
  }

  // --here passed. for :dartrix/template only, but we have to check every time
  if (Config.here) {
    result = Config.hereDir + '/' + result;
  }

  result = path.normalize(result);
  // print('''8af8c273-0e3a-4f4f-bda0-bfad7de91c98: final: $result''');

  return result;
}
