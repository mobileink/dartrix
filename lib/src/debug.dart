import 'package:logging/logging.dart';

import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/utils.dart';

var _log = Logger('debug');

bool debug = false;
bool verbose = false;

void debugData(Map xData) {
  if (xData != null) {
    _log.config("External datamap:");
    xData.forEach((k,v) {
        if (v is Map) {
          _log.config("xdata['$k']:");
          v.forEach((kk, vv) {
              _log.config("\txdata['$k']['$kk']: $vv");
          });
        } else {
          _log.config("xdata['$k']: $v");
        }
    });
  }
  _log.config("Datrix datamap:");
  tData.keys.toList()..sort()..forEach((k) {
      var v = tData[k];
      if (v is Map) {
        _log.config("tData['$k']:");
        v.forEach((kk, vv) {
            _log.config("\ttData['$k']['$kk']: $vv");
        });
      } else {
        _log.config("tData['$k']: $v");
      }
  });

  // _log.config("tData: $tData");
  // _log.config("tData['template']: ${tData['template']}");
  // _log.config("tData['package']['dart']: ${tData['package']['dart']}");
  // _log.config("tData['package']['java']: ${tData['package']['java']}");
  // _log.config("tData['class']: ${tData['class']}");
  // _log.config("tData['plugin-class']: ${tData['plugin-class']}");
  // _log.config("tData['domain']['user']: ${tData['domain']['user']}");
  // _log.config("tData['root']: ${tData['root']}");
  // _log.config("tData['outpath']: ${tData['outpath']}");
  // _log.config("tData['xpackage']: ${tData['xpackage']}");
  // _log.config("tData['sdk']['android']: ${tData['sdk']['android']}");
  // _log.config("tData['sdk']['flutter']: ${tData['sdk']['flutter']}");
  // _log.config("tData['segmap']: ${tData['segmap']}");
}

void debugPathRewriting(Map xData) {
  // debugData(xData);
  _log.config("Path rewriting:");
  _log.config("  --domain option: ${options['domain']} (default: ${argParser.getDefault('domain')})");
  _log.config("  external default domain: ${xData['domain']}");
  var from = tData['domain'];
  from = from.split('.').reversed.join('/');

  var to = options['domain'] ?? tData['domain'];
  to = to.split(".").reversed.join("/");
  _log.config("  rewrite rule: RDOMAINPATH => ${to}");
}

void debugOptions() {
  _log.config("Options:");
  _log.config("\tname: ${options.name}");
  _log.config("\targs: ${options.arguments}");
  _log.config("\toptions: ${options.options}");
  _log.config("\trest: ${options.rest} (isEmpty? ${options.rest.isEmpty})");


}
