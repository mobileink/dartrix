import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';

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
  var segs = _path.split(path.separator);
  var sm = segs.map((seg) {
      // _log.fine('seg: $seg');
      if (tData['segmap'][seg] == null) {
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
        switch (seg) {
          // case 'FILE':
          // break;
          case 'HOME':
          // Config.ppLogger.v('segmap HOME: ${tData["segmap"]["HOME"]}');
          // Config.ppLogger.v('HOME: ${Config.home}');

          if (tData['segmap']['HOME'] != Config.home) {
            if (path.isRelative(tData['segmap']['HOME'])) {
              tData['segmap']['HOME'] =
              path.normalize(Config.home + '/' + tData['segmap']['HOME']);
            }
          }
          // Config.ppLogger.v('rewritten segmap HOME: ${tData["segmap"]["HOME"]}');
          return tData['segmap'][seg];
          break;
          // case 'CWD':
          // break;
          default:
          return tData['segmap'][seg];
        }
      }
  });
  var result = sm.join('/');
  return result;
}
