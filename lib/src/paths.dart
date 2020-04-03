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

@exdefn(returns: "rewritten path")
String rewritePath(
  @exparam("file system path for template component")
  String _path)
{
  // Config.ppLogger.i('rewritePath: $_path');
  // tData['segmap'].forEach((k,v) {
  //     Config.logger.v('seg $k => $v');
  // });
  // List<String> segs = domPath.split(path.separator);

  // debug.debugData({});

  //List<String>
  var thePath = _path.replaceFirst(Directory.current.path + '/', '');
  var segs = thePath.split(path.separator);
  var sm = segs.map((seg) {
      // Config.ppLogger.i('seg: $seg');
      if (tData['segmap'][seg] == null) {
        // not in segment
        if (seg.endsWith('MUSTACHE')) {
          return seg.replaceAll('MUSTACHE', 'mustache');
        } else {
          // find segmap entry whose key is contained in seg
          var key;
          try {
            key = tData['segmap'].keys.singleWhere((key) {
                // print('TEST: $key');
                return seg.contains(key);
            });
            // print('MATCH: $seg');
            return seg.replaceAll(key, tData['segmap'][key]);
          } catch(e) {
            //print(e);
            // print('nomatch: $seg');
          }
          return seg;

          // no rewrite for full seg, check for partial match
          // var base = path.basenameWithoutExtension(seg);
          // if (tData['segmap'][base] == null) {
          //   // no rewrite for FOO of FOO.bar, check for BAR of foo.BAR
          //   var ext = path.extension(seg);
          //   if (tData['segmap'][ext] == null) {
          //     return seg;
          //   } else {
          //     var rw = base + tData['segmap'][ext];
          //     return rw;
          //   }
          // } else {
          //   // e.g. FOO.bar matched FOO
          //   var rw;
          //   if (base == 'DOTDIR_D') {
          //     rw = tData['segmap'][base]; //  + path.extension(seg) + '.d';
          //   } else {
          //     rw = tData['segmap'][base] + path.extension(seg);
          //   }
          //   return rw;
          // }
        }
      } else {
        // in segmap
        switch (seg) {
          // case 'CWD': return seg; // will be reprocessed below, for metas
          // break;
          // case 'HOME':
          // // Config.ppLogger.v('segmap HOME: ${tData["segmap"]["HOME"]}');
          // // Config.ppLogger.v('HOME: ${Config.home}');

          // if (tData['segmap']['HOME'] != Config.home) {
          //   if (path.isRelative(tData['segmap']['HOME'])) {
          //     tData['segmap']['HOME'] =
          //     path.canonicalize(Config.home + '/' + tData['segmap']['HOME']);
          //   }
          // }
          // // Config.ppLogger.v('rewritten segmap HOME: ${tData["segmap"]["HOME"]}');
          // return tData['segmap'][seg];
          // break;
          default:
          if (Config.meta != null) {
            if (tData['segmap']['_META'].contains(seg)) {
              // print('seg: $seg : ${tData["segmap"][seg]}');
              return tData['segmap'][seg];
            } else {
              return seg;
            }
          } else {
            return tData['segmap'][seg];
          }
        }
      }
  });
  // print('segmap._META: ${tData["segmap"]["_META"]}');

  var result = sm.join('/');

  // disallow writing outside of CWD
  if (result.startsWith('/')) {
    Config.ppLogger.w('Templates may not write outside of current working directory and below. Stripping initial \'/\' from output path.');
    result = result.substring(1);
  }

  // print('''8d4898e3-3931-4c52-b837-73e068f78ab9:  result $result''');

  // meta: insert path prefix
 if (Config.meta != null) {
   // result = result.replaceFirst('_CWD', '.');
   // if --here
   // print('Config.meta: ${Config.meta}');
   if (Config.meta == Meta.template) {
     result = 'templates/' + tData['_index'] + '/' + result;
     // result = 'templates/' + tData['_index'] + '/' + result;
   } else if (Config.meta == Meta.plugin) {
     //FIXME: insert name param with _dartrix
     result = tData['_plugin_name'] + '/' + result;
   }
   result = result.replaceFirst('YAML', '.yaml');
    // result = result.replaceFirst('NAME', 'appname');
  } else {
    // result = result.replaceAll('CWD', tData['segmap']['CWD']);
    if (tData['_out_prefix'] != null) {
      result = tData['_out_prefix'] + '/' + result;
    }
  }

  // --here passed. for :dartrix/template only, but we have to check every time
  if (Config.here) {
    result = Config.hereDir + '/' + result;
  }

  result = path.normalize(result);
  // print('''8af8c273-0e3a-4f4f-bda0-bfad7de91c98:  meta after: $result''');

  return result;
}
