import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:package_config/package_config.dart';
import 'package:sprintf/sprintf.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/data.dart';
// import 'package:dartrix/src/utils.dart';

// var _log = Logger();

bool debug = false;

void debugData(Map xData) async {
  Config.logger.d('Datrix datamap:');
  var sorted = SplayTreeMap.from(tData);
  var encoder = JsonEncoder.withIndent('    ');
  var j = encoder.convert(sorted);
  Config.ppLogger.v(j);
}

void debugConfig() async {
  Config.logger.d('Config:');
  Config.logger.d('\tverbose: ${Config.verbose}');
  Config.logger.d('\tdebug: ${Config.debug}');
  Config.logger.d('\tdryRun: ${Config.dryRun}');
  Config.logger.d('\tcwd: ${Directory.current.path}');
  Config.logger.d('\thome: ${Config.home}');
  Config.logger.d('\tisoHome: ${Config.isoHome}');
  Config.logger.d('\tuserCache: ${Config.userCache}');
  Config.logger.d('\tsysCache: ${Config.sysCache}');
  Config.logger.d('\tappName: ${Config.appName}');
  Config.logger.d('\tappSfx: ${Config.appSfx}');
  Config.logger.d('\tappPkgRoot: ${Config.appPkgRoot}');
  Config.logger.d('\tlibPkgRoot: ${Config.libPkgRoot}');
  Config.logger.d('\ttemplateRoot: ${Config.templateRoot}');
  Config.logger.d('\tappVersion: ${await Config.appVersion}');
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

void debugArgResults(ArgResults results) {
  Config.logger.d('ArgResults:');
  Config.logger.d('\tresults: ${results.options}');
  results.options.forEach((o) {
    if (results.wasParsed(o)) {
      Config.logger.d('\t$o: ${results[o]}');
    }
  });
  Config.logger.d('\trest: ${results.rest}');
  // Config.logger.d('\tname: ${results.name}');
}

void debugListBuiltins() {
  Config.logger.d('Available builtin templates:');
  builtinTemplates.forEach((k, v) {
    var spacer = (k.length < 8) ? '\t\t' : '\t';
    Config.logger.d('\t${k}${spacer}${v}');
  });
}

void debugPackageConfig(PackageConfig pkgConfig) {
  Config.ppLogger.v('Package Config (.packages) content:');
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
