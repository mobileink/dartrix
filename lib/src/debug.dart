import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/utils.dart';

var _log = Logger('debug');

bool debug = false;

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
  // _log.config("tData['plugin']: ${tData['plugin']}");
  // _log.config("tData['sdk']['android']: ${tData['sdk']['android']}");
  // _log.config("tData['sdk']['flutter']: ${tData['sdk']['flutter']}");
  // _log.config("tData['segmap']: ${tData['segmap']}");
}

void debugPathRewriting(Map xData) {
  // debugData(xData);
  _log.config("Path rewriting:");
  _log.config("  --domain option: ${Config.options['domain']} (default: ${Config.argParser.getDefault('domain')})");
  _log.config("  external default domain: ${xData['domain']}");
  var from = tData['domain'];
  from = from.split('.').reversed.join('/');

  var to = Config.options['domain'] ?? tData['domain'];
  to = to.split(".").reversed.join("/");
  _log.config("  rewrite rule: RDOMAINPATH => ${to}");
}

void debugOptions() {
  _log.config("Options:");
  _log.config("\targs: ${Config.options.arguments}");
  _log.config("\toptions: ${Config.options.options}");
  _log.config("\trest: ${Config.options.rest}");
  // _log.config("\tname: ${Config.options.name}");
}

void debugListBuiltins() {
  _log.config("Available builtin templates:");
  builtinTemplates.forEach((k,v) {
      var spacer = (k.length < 8) ? "\t\t" : "\t";
      _log.config("\t${k}${spacer}${v}");
  });
}

void debugPackageConfig(PackageConfig pkgConfig) {
  _log.config("debugPackageConfig");
  _log.config("extra data: ${pkgConfig.extraData}");
  _log.config("version: ${pkgConfig.version}");
  _log.config("maxVersion: ${PackageConfig.maxVersion}");
  _log.config("packages (${pkgConfig.packages.length}) = contents of .packages file:");
  // file:///$HOME/.pub-cache/hosted/pub.dartlang.org/
  _log.config("Package URIs, relative to ~/.pub-cache/hosted/pub.dartlang.org/:");
  pkgConfig.packages.forEach((pkg) {
      // NB: the uri is "file://${HOME}/.pub-cache/hosted/pub.dartlang.org/"
      // but the .path property strips the file:// scheme, so we need:
      String pfx = "${Config.home}/.pub-cache/hosted/pub.dartlang.org/";
      // _log.config("pfx: $pfx");
      var pkgUriRoot = pkg.packageUriRoot.path.replaceFirst(pfx, '');
      var pkgRoot = pkg.root.path.replaceFirst(pfx, '');
      _log.config("${pkg.name}: uriRoot: $pkgUriRoot; root: ${pkgRoot}\n");
  });
}
