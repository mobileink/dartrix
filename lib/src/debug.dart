// import 'package:logger/logger.dart';
import 'package:package_config/package_config.dart';
import 'package:sprintf/sprintf.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
// import 'package:dartrix/src/utils.dart';

// var _log = Logger();

bool debug = false;

void debugData(Map xData) {
  if (xData != null) {
    Config.logger.d('External datamap:');
    xData.forEach((k, v) {
      if (v is Map) {
        Config.logger.d('xdata["$k"]:');
        v.forEach((kk, vv) {
          Config.logger.d('\txdata["$k"]["$kk"]: $vv');
        });
      } else {
        Config.logger.d('xdata["$k"]: $v');
      }
    });
  }
  Config.logger.d('Datrix datamap:');
  tData.keys.toList()
    ..sort()
    ..forEach((k) {
      var v = tData[k];
      if (v is Map) {
        Config.logger.d('tData["$k"]:');
        v.forEach((kk, vv) {
          Config.logger.d('\ttData["$k"]["$kk"]: $vv');
        });
      } else {
        Config.logger.d('tData["$k"]: $v');
      }
    });
}

void debugPathRewriting(Map xData) {
  // debugData(xData);
  Config.logger.d('Path rewriting:');
  Config.logger.d(
      '  --domain option: ${Config.options["domain"]} (default: ${Config.argParser.getDefault("domain")})');
  Config.logger.d('  external default domain: ${xData["domain"]}');
  var from = tData['domain'];
  from = from.split('.').reversed.join('/');

  var to = Config.options['domain'] ?? tData['domain'];
  to = to.split('.').reversed.join('/');
  Config.logger.d('  rewrite rule: RDOMAINPATH => ${to}');
}

void debugOptions() {
  Config.logger.d('Options:');
  // Config.logger.d('\targs: ${Config.options.arguments}');
  Config.logger.d('\toptions: ${Config.options.options}');
  Config.options.options.forEach((o) {
    if (Config.options.wasParsed(o)) {
      Config.logger.d('\t$o: ${Config.options[o]}');
    }
  });
  Config.logger.d('\trest: ${Config.options.rest}');
  // Config.logger.d('\tname: ${Config.options.name}');
}

void debugListBuiltins() {
  Config.logger.d('Available builtin templates:');
  builtinTemplates.forEach((k, v) {
    var spacer = (k.length < 8) ? '\t\t' : '\t';
    Config.logger.d('\t${k}${spacer}${v}');
  });
}

void debugPackageConfig(PackageConfig pkgConfig) {
  Config.debugLogger.d('debugPackageConfig:::::');
  Config.logger.d('extra data: ${pkgConfig.extraData}');
  Config.logger.d('version: ${pkgConfig.version}');
  Config.logger.d('maxVersion: ${PackageConfig.maxVersion}');
  Config.logger.d(
      'packages (${pkgConfig.packages.length}) = contents of .packages file:');
  // file:///$HOME/.pub-cache/hosted/pub.dartlang.org/
  Config.logger
  .d('File paths relative to ~/.pub-cache/hosted/pub.dartlang.org/:');

  var pn = sprintf('%-24s', ['Package Name']);
  var pur = sprintf('%-40s', ['Package URI Root']);
  var pr = sprintf('%-40s', ['Package Root']);
  Config.logger.d(infoPen('\t${pn}${pr}${pur}'));
  pkgConfig.packages.forEach((pkg) {
    // NB: the uri is 'file://${HOME}/.pub-cache/hosted/pub.dartlang.org/'
    // but the .path property strips the file:// scheme, so we need:
    //String
    var pfx = '${Config.home}/.pub-cache/hosted/pub.dartlang.org/';
    // Config.logger.d('pfx: $pfx');
    var pkgUriRoot = pkg.packageUriRoot.path.replaceFirst(pfx, '');
    var pkgRoot = pkg.root.path.replaceFirst(pfx, '');

    var pn = sprintf('%-24s', [pkg.name]);
    var pur = sprintf('%-40s', [pkgUriRoot]);
    var pr = sprintf('%-40s', [pkgRoot]);

    var outline;
    if (pkg.name.endsWith('dartrix')) {
      outline = infoPen('\t${pn}${pr}${pur}');
    } else {
      outline = '\t${pn}${pr}${pur}';
    }

    Config.logger.d(outline);
  });
  Config.logger.d('');
}
