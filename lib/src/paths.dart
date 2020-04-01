import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;

// Path Rewriting

// Built-in rewrite params:

// ROOT : '/'
// HOME : $HOME
// CWD  : Current Working Directory = Directory.current

String rewritePath(String _path) {
  // Config.ppLogger.i('rewritePath: $_path');
  // tData['segmap'].forEach((k,v) {
  //     Config.logger.v('seg $k => $v');
  // });
  // List<String> segs = domPath.split(path.separator);
  //List<String>
  var thePath = _path.replaceFirst(Directory.current.path + '/', '');
  // print('thePath: $thePath');
  var segs = thePath.split(path.separator);
  var sm = segs.map((seg) {
      // Config.ppLogger.i('seg: $seg');
      if (tData['segmap'][seg] == null) {
        // not in segment
        if (seg.endsWith('MUSTACHE')) {
          return seg.replaceAll('MUSTACHE', 'mustache');
        } else {
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
            if (base == 'DOTDIR_D') {
              rw = tData['segmap'][base]; //  + path.extension(seg) + '.d';
            } else {
              rw = tData['segmap'][base] + path.extension(seg);
            }
            return rw;
          }
        }
      } else {
        // in segmap
        switch (seg) {
          case 'CWD': return seg; // will be reprocessed below, for metas
          break;
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
          break;
          default:
          if (Config.meta) {
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

  // print('result: $result');
  // print('meta before: $result');
 if (Config.meta) {
   result = result.replaceFirst('_CWD', '.');
   // if --here
   result = result.replaceFirst('_TEMPLATES', '.templates');
   result = result.replaceFirst('YAML', '.yaml');
    // result = result.replaceFirst('NAME', 'appname');
  } else {
    result = result.replaceAll('CWD', tData['segmap']['CWD']);
  }
  result = path.normalize(result);
  // print('meta after: $result');

  return result;
}
