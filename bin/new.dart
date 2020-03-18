import 'dart:async';
import 'dart:core';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/cmd_run.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/which.dart';
import 'package:pub_cache/pub_cache.dart';
import 'package:resource/resource.dart';
// import 'package:scratch_space/scratch_space.dart';
import 'package:strings/strings.dart';

import 'package:dartrix/src/builtins.dart';
import 'package:dartrix/src/data.dart';
import 'package:dartrix/src/debug.dart' as debug;
import 'package:dartrix/src/externals.dart';
import 'package:dartrix/src/utils.dart';

var _log = Logger('new');

// final myScratchSpaceResource =
//     new Resource(() => ScratchSpace());

String http_parser_pkg = "package:http_parser";
String hello_pkg = "package:hello_template";

void getResource (String _pkg) async {

  // 1. try pubcache
  //   a. globals
  //   b. hosted
  // 2. .packages?

  _log.finer("pubcache: ${PubCache.getSystemCacheLocation()}");

  PubCache pc = PubCache();
  var cachedPkgs = pc.getCachedPackages();
  // cachedPkgs.forEach((pkg) => _log.finer("pkg: $pkg"));
  var globalApps = pc.getGlobalApplications();
  globalApps.forEach((global) => _log.finer("global name: ${global.name}"));
  Application gapp = globalApps.firstWhere((app) => app.name == "hello_template");

  // var pkgs = globalApps.map((app) => app.getDefiningPackageRef().resolve());
  // pkgs.forEach((pkg) => _log.finer("pkg/locn : ${pkg.name}/${pkg.location}"));

  Package thePkg = gapp.getDefiningPackageRef().resolve();
  _log.finer("name/locn:  ${thePkg.name} / ${thePkg.location}");

  var icfg = await Isolate.packageConfig;
  _log.finer("icfg: $icfg");

  String pkg = "package:${_pkg}/dartrix.dart";
  var resource = new Resource(pkg);
  _log.finer("dep uri: ${resource.uri}");

  // String pkgResolver = "file:///
  // var resolver = SyncPackageResolver.root(resource.uri);
  // _log.finer("resolver: ${resolver}");
  // _log.finer("resolver packageConfigMap: ${resolver.packageConfigMap}");
  // _log.finer("resolver packageConfigUri: ${resolver.packageConfigUri}");
  // _log.finer("resolver packageRoot: ${resolver.packageRoot}");
  // var pkgPath = resolver.packageUriFor(pkg);
  // _log.finer("resolver packagePath(): ${pkgPath}");
  // var x = resolver.packagePath('package:hello_template/'); // .then((x) => _log.finer("X $x"));
  // _log.finer("pkg path: $x");
  // // var hiUri = await resolver.resolveUri('package:hello_template/');
  // // _log.finer("hiUri: $hiUri");


  // var string = await resource.readAsString(encoding: utf8);
  // _log.finer("FOO: $manifest")  _log.finer("manifest: ${resource.uri}");

  Uri theUri = Uri.parse("file://" + thePkg.location.path + "/lib/dartrix.dart");
  _log.finer("theUri: $theUri");

  final rPort = ReceivePort();
  // await Isolate.spawnUri(resource.uri, [], null);
  await Isolate.spawnUri(theUri, [resource.uri.path], null, onExit: rPort.sendPort);
  // await Isolate.spawn(entryPoint, null, onExit: rPort.sendPort);
  await rPort.first;

  // sleep(const Duration(seconds:1));

  // var pkgcfg = await Isolate.packageConfig;
  // _log.finer("Uri pkg config: $pkgcfg");

  // var xuri = Uri.dataFromString('package:hello_template/');
  // var uri = await Isolate.resolvePackageUri(xuri);
  // // var uri2 = uri.resolve(uri);
  // _log.finer("URI: $uri");

}


void transformDirectory(String source, String destination, Map data) {

  var inDir = Directory(source);
  var outDir = Directory(destination);

  List inFiles = inDir.listSync(recursive: true);
  inFiles.removeWhere((f) => f.path.endsWith("~"));

  var orgSegs = data["org"].replaceAll(".", "/");

  List dirs = List.from(inFiles);
  dirs.retainWhere((f) => f is Directory);
  dirs.forEach((d) {
      var od = d.path.replaceAll(source + "/", '');
      // var od = d.path.replaceAll('mustache/', ''); // data['package']['dart']);
      od = od.replaceAll('greetings', data['package']['dart']);
      // _log.finer("dir: $od");
      var segs = od.split("org/example");
      // _log.finer("segs: $segs");
      var out = "plugins/" + data['package']['dart'] + "/" + segs.join(orgSegs);
      // _log.finer("out: $out");
      var outDir = Directory(out);

      _log.finer(outDir);
      outDir.createSync(recursive: true);
  });

  inFiles.removeWhere((f) => f is Directory);

  List templates = List.from(inFiles);

  inFiles.removeWhere((f) => f.path.endsWith("mustache"));
  var outFiles = inFiles.map((f) => File(f.path.replaceAll('mustache', data['package']['dart']).replaceAll('greetings', data['package']['dart'])));

  // _log.finer("FILES:");
  // outFiles.forEach((f) => _log.finer(f));

  inFiles.forEach((f) {
      var of = f.path.replaceAll(source + "/", '');
      // var of = f.path.replaceAll(RegExp('^mustache/'), '');
      // data['package']['dart']);
      of = of.replaceAll('greetings', data['package']['dart']);
      of = "plugins/" + data['package']['dart'] + "/" + of;
      var outFile = File(of);
      // _log.finer("COPY: $f");
      _log.finer(" => $outFile");
      f.copySync(of);
  });


  templates.retainWhere((f) => f.path.endsWith("mustache"));
  templates.forEach((t) {
      var out = t.path.replaceAll(source + "/", '');
      out = out.replaceAll('greetings', data['package']['dart']);
      out = out.replaceAll('Greetings', data['plugin-class']);
      out = out.replaceFirst(RegExp('^mustache/'), '') // data['package']['dart'])
      .replaceFirst(RegExp('\.mustache\$'), '');

      var segs = out.split("org/example");
      // _log.finer("file: $out");
      // _log.finer("segs: $segs");
      out = segs.join(orgSegs);
      // _log.finer("out: $out");
      out = "plugins/" + data['package']['dart'] + "/" + out;

      // _log.finer(t);
      _log.finer(" => $out");
      var contents;
      contents = t.readAsStringSync();
      var template = Template(contents, name: t.path, htmlEscapeValues: false);
      var newContents = template.renderString(data);
      File(out).writeAsStringSync(newContents);
  });
}

void validateSnakeCase(String pkg) {
  final r = RegExp(r"^[a-z_][a-z0-9_]*$");
  if ( ! r.hasMatch(pkg) ) {
    _log.finer("Invalid name (snake_case): $pkg");
    exit(0);
  }
}

void validateCamelCase(String name) {
  final r = RegExp(r"^[A-Z][A-Za-z0-9_]*$");
  if ( ! r.hasMatch(name) ) {
    _log.finer("Invalid name (CamelCase): $name");
    exit(0);
  }
}

void validateTemplateName(String t) {
  validateSnakeCase(t);
}

String getInDir(String template) {

  // If template is built-in, proceed, else call resolution fn

  String p = path.prettyUri(Platform.script.toString());
  // _log.finer("inDir 1: $p");
  String inDir = path.dirname(p) + "/..";
  var inPfx = path.canonicalize(inDir);
  // _log.finer("inPfx 2: $inPfx");
  if (template == 'split-plugin') {
    inDir = inPfx + "/mustache/plugins/greetings-services";
  } else {
    inDir = inPfx + "/mustache/plugins/greetings";
  }
}

void main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root..onRecord.listen((record) {
      var level;
      switch (record.level.name) {
        case 'SHOUT': level = shoutPen(record.level.name); break;
        case 'SEVERE': level = severePen(record.level.name); break;
        case 'WARNING': level = warningPen(record.level.name); break;
        case 'INFO': level = infoPen(record.level.name); break;
        case 'CONFIG': level = configPen(record.level.name); break;
        default: level = record.level.name; break;
      }
      print('${record.loggerName} ${level}: ${record.message}');
  });

  argParser = ArgParser(allowTrailingOptions: false);
  argParser.addOption('template', abbr: 't', // defaultsTo: 'hello',
    valueHelp: "[a-z][a-z0-9_]*",
    help: "Template name.",
    // callback: (t) => validateTemplateName(t)
  );
  argParser.addOption('outpath', abbr: 'o', defaultsTo: './',
    help: "Output path.  Prefixed to --root dir.",
    valueHelp: "path."
  );
  argParser.addOption('root', abbr: 'r',
    valueHelp: "directory, without '/'.",
    help: "Root output segment.  Defaults to value of --package arg (i.e. 'hello')."
    // callback: (pkg) => validateSnakeCase(pkg)
  );
  argParser.addOption('domain', abbr: 'd', defaultsTo: 'example.org',
    help: "Domain name. Must be legal as a Java package name;\ne.g. must not begin with a number, or match a Java keyword.",
    valueHelp: "segmented.domain.name"
  );
  argParser.addOption('package', abbr: 'p', defaultsTo: 'hello',
    valueHelp: "[_a-z][a-z0-9_]*",
    help: "snake_cased name.  Used e.g. as Dart package name.",
    callback: (pkg) => validateSnakeCase(pkg)
  );
  argParser.addOption('class', abbr: 'c', defaultsTo: 'Hello',
    valueHelp: "[A-Z][a-zA-Z0-9_]*",
    help: "CamelCased name. Used as class/type name.\nDefaults to --package value, CamelCased (i.e. 'Hello').\nE.g. -p foo_bar => -c FooBar.",
    callback: (name) => validateCamelCase(name)
  );
  argParser.addOption('xpackage', abbr: 'x',
    valueHelp: "path:path/to/local/pkg | package:pkg_name",
    help: "External template package"
    // defaultsTo: 'plugin',
    // callback: (t) => validateTemplateName(t)
  );
  // argParser.addFlag('list', abbr: 'l',
  //   help: "List plugins.",
  //   defaultsTo: false,
  // );
  argParser.addFlag('force', abbr: 'f', defaultsTo: false);
  argParser.addFlag('help', abbr: 'h', defaultsTo: false);
  argParser.addFlag('debug', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);

  argParser.addFlag('manpage', defaultsTo: false);

  var command = ArgParser.allowAnything();
  argParser.addCommand('data:', command);

  options = argParser.parse(args);

  if (options['help']) {
    print("\n\t\tDartrix Templating System - 'new' command\n");
    print("Usage: \$ pub global run dartrix:new [args]\n");
    print(argParser.usage);
    print("\nBuiltin templates:");
    print("\tplugin");
    print("\tsplitplugin");
    print("\tapp-dart");
    print("\tapp-flutter");
    print("\tpackage");
    print("\tlib\n");
    print("\nOther commands available:\n");
    print("\tdartrix:doc\t\tMore detailed documentation");
    print("\tdartrix:list\t\tList available templates");
    print("\tdartrix:dev\t\tDocumentation for template development\n");
    exit(0);
    // if (options['xpackage'] == null) {
    // }
  }

  bool runInShell = true; //Platform.isWindows;
  if (options['manpage']) {
    // ProcessCmd cmd = processCmd('man', ['ls'], runInShell: runInShell);
    // await runCmd(cmd, stdout: stdout);
    var shell = Shell();
    await shell.run("man ls");
    exit(0);
  }

  if (options['debug']) debug.debug = true;

  var cmd = options.command;
  // _log.finer("cmd: $cmd");

  if ( options.rest.isNotEmpty && (cmd == null)) {
    if ( options.rest[0] == 'data' ) {
      print("Error: unrecognized args: ${options.rest} (did you forget the : in 'data:' ?)");
    } else {
      print("Error: unrecognized args: ${options.rest}");
    }
    exit(0);
  }

  var cmdOptions;
  if (cmd != null) {
    cmdOptions = command.parse(options.command.arguments);
    _log.finer("command: ${options.command.name}");
    _log.finer("command args: ${options.command.arguments}");
    _log.finer("command opts: ${options.command.options}");
    // _log.finer("command rest: ${options.command.rest}");
  }

  debug.verbose = options['verbose'];

  tData['domain'] = options['domain'];

  if (options['root'] == null) {
    tData['segmap']['ROOTPATH'] = './';
  } else {
    tData['segmap']['ROOTPATH'] = options['root'];
  }

  tData['package']['dart'] = options['package'];
  // "package.java" = Java package string, e.g. org.example.foo
  String dartPackage = options['package'];
  String rdomain = tData['domain'].split('.').reversed.join(".");
  String javaPackage = rdomain + "." + dartPackage;
  tData['package']['java'] = javaPackage;

  tData['segmap']['RDOMAINPATH'] = rdomain.replaceAll('.', '/');

  var pluginClass = (options['class'] == 'Hello')
  ? dartPackage.split("_").map(
    (s)=> capitalize(s)).join()
  : options['class'];

  tData['plugin-class'] = pluginClass;
  tData['class'] = pluginClass;
  tData['segmap']['CLASS'] = options['class'];

  tData['root'] = options['root'];
  tData['outpath'] = options['outpath'];

  tData['dartrix']['force'] = options['force'];

  // linux, macos, windows, android, ios, fuchsia
  tData['platform'] = Platform.operatingSystem;
  tData['segmap']['platform'] = Platform.operatingSystem;

  // Theses properties are for android/local.properties.
  // _log.finer("resolvedExecutable: ${Platform.resolvedExecutable}");
  // FIXME: find a better way?
  var androidExecutable = whichSync('android');
  // _log.finer("android exe: $androidExecutable");
  var androidSdk = path.joinAll(
    path.split(androidExecutable)
    ..removeLast()
    ..removeLast());
  tData['sdk']['android'] = androidSdk;

  var flutterExecutable = whichSync('flutter');
  // _log.finer("flutter exe: $flutterExecutable");
  var flutterSdk = path.joinAll(
    path.split(flutterExecutable)
    ..removeLast()
    ..removeLast());
  tData['sdk']['flutter'] = flutterSdk;

  if (debug.debug) {
    _log.finer("dart executable: $dartExecutable");
    _log.finer("dartSdkBinDirPath: $dartSdkBinDirPath");
    _log.finer("dartSdkDirPath: $dartSdkDirPath");
  }

  // var outPathPrefix = options['outpath'];
  // _log.finer("outPathPrefix: $outPathPrefix");

  // var rootDir = (options['root'] == null)
  // ? "/"
  // : "/" + options['root'];

  // var outPath = outPathPrefix + rootDir;

  // if (outPathPrefix != "./") {
  //   if (Directory(outPath).existsSync()) {
  //     if ( !options['force'] ) {
  //       _log.severe("Directory '$outPath' already exists. Use -f to force overwrite.");
  //       exit(0);
  //     }
  //     _log.warning("Overwriting plugins/$outPath.");
  //   }
  // }

  var template = options['template'];
  tData['template'] = template;
  tData['xpackage'] = options['xpackage'];

  if (debug.debug) debug.debugOptions();

  if (tData['xpackage'] != null) {
    generateFromXPackage(tData['xpackage'], template,
      (options.command == null)? null : options.command.arguments);
  } else {
    initBuiltinTemplates();
    if ( builtinTemplates.contains(template) ) {
      // process builtin
    } else {
      _log.finer("EXCEPTION: template $template not found.");
      exit(0);
    }
  }
  // _log.finer("script locn: ${Platform.script.toString()}");
  // _log.finer("built-ins: $builtinTemplates");

  String inDir = getInDir(options['template']);
  // _log.finer("inDir: $inDir");

  // getResource("hello_template");

  // if (template == 'plugin')
  // transformDirectory(inDir, outPathPrefix, tData);

}


