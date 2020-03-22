// man.dart - display manpages

import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';

import 'package:dartrix/dartrix.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/utils.dart';

void getManPages(String rootDir) {}

void printManpage(String lib, String rootDir, String manPage) async {
  //String
  var manDir = rootDir + '/man';
  manDir = path.normalize(manDir);
  // Config.logger.i('manDir: $manDir');
  // Config.logger.i('lib: $lib');
  manPage = manPage ?? lib + '_dartrix';
  // Config.logger.i('manPage: $manPage');
  //List
  var pages = Directory(manDir).listSync();
  pages.retainWhere((f) => f is File);
  pages.retainWhere((f) => num.tryParse(path.extension(f.path)) != null);
  //File
  var manPageF = pages.firstWhere(
      (f) => path.basenameWithoutExtension(f.path) == manPage, orElse: () {
    print('No manual entry for $manPage in library ${lib}_dartrix');
    exit(0);
    return null;
  });
  // Config.logger.i('found manpage $manPageF');

  // fixme: deal with multiples, e.g. foo.1, foo.5

  // bool runInShell = true; //Platform.isWindows;
  if (manPage != null) {
    // ProcessCmd cmd = processCmd('man', ['ls'], runInShell: runInShell);
    // await runCmd(cmd, stdout: stdout);
    var shell = Shell();
    await shell.run('man ${manPageF.path}');
    exit(0);
  }
}

void manBuiltins(ArgResults options) async {
  print('manBuiltins ${options.arguments}');
  var template = options['template'] ?? 'dartrix';
  Config.logger.i('template: $template');
  //Uri
  var packageConfigUri = await Isolate.packageConfig;
  Config.logger.i('packageConfigUri $packageConfigUri');
  //String
  var libDir = path.dirname(packageConfigUri.path);
  printManpage('dartrix', libDir, template);
}

void manPlugins(ArgResults options) async {
  // print('manPlugins');
  var lib = options.rest[0];
  var libDir = await resolvePkgRoot('package:' + lib + '_dartrix');
  if (Config.verbose) {
    Config.logger.i('resolved $lib to package:${lib}_dartrix to $libDir');
  }
  var template = options['template'];
  printManpage(lib, libDir, template);
}

void printUsage(ArgParser argParser) async {
  print('dartrix:man, version 0.1.0\n');
  print('Usage: pub global run dartrix:man [tvh] [cmd | library]\n');
  // print('Options (for builtins and plugin libraries only):\n');
  print(argParser.usage);

  print('\nCommands:');
  // print('\tdev\t\tDocumentation for template developers');
  print('\tlist\t\tList available template libraries.');
  print('\tnew\t\tUse templates to generate files.');
  print('\tman\t\tManpages\n');

  print('Available template libraries:');
  //List<Package>
  var pkgs = await getPlugins('_dartrix');
  print('\tdartrix\t\tBuiltin templates');
  pkgs.forEach((pkg) {
    var pkgName = pkg.name.replaceFirst(RegExp('_dartrix\$'), '');
    var spacer = pkgName.length < 8 ? '\t\t' : '\t';
    var docString = getDocstring(pkg);
    print('\t${pkgName}${spacer}${docString}');
  });
  print('');
  // print('\tdartrix\t\tBuiltin templates. Optional; if no <libname> specified,');
  // print('\t\t\tthe -t option refers to a builtin template.');
  // print('\t<libname>\tDocumentation for template library plugin.\n');
  // print('where <libname> is the name part of a Dartrix plugin package; for');
  // print('example, the libname for package:greetings_dartrix is 'greetings.'\n');
}

void main(List<String> args) async {
  var argParser = ArgParser(usageLineLength: 120);
  // argParser.addOption('library', abbr: 'l',
  //   valueHelp: 'name',
  //   help: 'A Dartrix template library name, without prefix "package:" and suffix "_dartrix", e.g. "greetings" for package:greetings_dartrix',
  //   defaultsTo: 'dartrix',
  //   // callback: (t) => validateTemplateName(t)
  // );
  argParser.addOption('template',
      abbr: 't', valueHelp: '[a-z_][a-z0-9_]*', help: 'Template name.'
      // defaultsTo: 'hello',
      // callback: (t) => validateTemplateName(t)
      );
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('help', abbr: 'h', defaultsTo: false);
  argParser.addFlag('debug', defaultsTo: false);

  if (args.isEmpty) {
    print('What dartrix man page do you want?');
    exit(0);
  }

  Config.options = argParser.parse(args); // .sublist(1));
  // debug.debugOptions();

  if (Config.options['verbose']) Config.verbose = true;

  // if (Config.options.rest.isEmpty) {
  if (Config.options['help']) {
    await printUsage(argParser);
    exit(0);
  }
  // }

  if (Config.options.rest.isNotEmpty) {
    switch (Config.options.rest[0]) {
      case 'dartrix_config':
        Config.logger.w('dartrix_config manpage not implemented');
        break;
      case 'dev':
        Config.logger.w('manpage dev not implemented');
        break;
      case 'man':
        Config.logger.w('manpage man not implemented');
        break;
      case 'list':
        Config.logger.w('manpage list not implemented');
        break;
      case 'new':
        Config.logger.w('manpage new not implemented');
        break;
      case 'help':
      case '-h':
      case '--help':
        await printUsage(argParser);
        exit(0);
        break;
      default:
        if (Config.options.rest[0] == 'dartrix') {
          manBuiltins(Config.options);
        } else {
          // if (args[0].startsWith('-')) {
          //   manBuiltin(Config.options);
          // } else {
          manPlugins(Config.options);
          // }
        }
    }
  }
}
