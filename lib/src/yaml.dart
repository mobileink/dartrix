import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:safe_config/safe_config.dart';
import 'package:yaml/yaml.dart';

import 'package:dartrix/src/config.dart';
// import 'package:dartrix/src/resolver.dart';
import 'package:dartrix/src/utils.dart';

// safe_config yaml classes
class Params extends Configuration {
  // Params() : super() {
  @optionalConfiguration
  List<UserParam> user;
  @optionalConfiguration
  // List<Map<String,SysParam>> sys;
  List<SysParam> sys;
}

class Param extends Configuration {
  // Param() : super();
  // Param.fromFile(String fileName) : super.fromFile(File(fileName));
  Param(
      {this.id,
      this.name,
      this.abbr,
      this.docstring,
      this.help,
      this.typeHint,
      this.negatable,
      this.defaultsTo});

  @optionalConfiguration
  String id;
  @optionalConfiguration
  String name;
  @optionalConfiguration
  String abbr;
  @optionalConfiguration
  String docstring;
  @optionalConfiguration
  String help;
  // String typeHelp; // parser 'valueHelp'
  @optionalConfiguration
  String typeHint; // _plugin, _template, _out
  @optionalConfiguration
  String defaultsTo;
  @optionalConfiguration
  bool negatable;
  @optionalConfiguration
  bool hidden = false;
  @optionalConfiguration
  bool private = false;
  @optionalConfiguration
  String seg;
  @optionalConfiguration
  String hook;
}

class UserParam extends Param {
  // Param() : super();
  // Param.fromFile(String fileName) : super.fromFile(File(fileName));
  UserParam(
      {this.name,
      this.abbr,
      this.docstring,
      this.help,
      this.typeHint,
      this.negatable,
      this.defaultsTo});

  @override
  String name;
  @optionalConfiguration
  @override
  String abbr;
  @override
  String docstring;
  @optionalConfiguration
  @override
  String help;
  // String typeHelp; // parser 'valueHelp'
  // @optionalConfiguration
  @override
  String typeHint; // _plugin, _template, _out
  @optionalConfiguration
  @override
  String defaultsTo;
  @optionalConfiguration
  @override
  bool negatable;
  @optionalConfiguration
  @override
  bool hidden = false;
  @optionalConfiguration
  @override
  bool private = false;
  @optionalConfiguration
  @override
  String seg;
  @optionalConfiguration
  @override
  String hook;
}

class SysParam extends Param {
  // SysParam(this.param) : super();
  SysParam(
      {this.id,
      this.name,
      this.abbr,
      docstring,
      help,
      typeHint,
      negatable,
      defaultsTo})
      : super(
            name: name,
            abbr: abbr,
            docstring: docstring,
            help: help,
            typeHint: typeHint,
            negatable: negatable,
            defaultsTo: defaultsTo);
  @override
  String id;
  // Overrides
  @optionalConfiguration
  @override
  String name;
  @optionalConfiguration
  @override
  String abbr;
  // @optionalConfiguration
  // String defaultsTo;
  @optionalConfiguration
  @override
  bool private = false;
  @optionalConfiguration
  @override
  bool hidden = false;

  @override
  List<String> validate() {
    // print('''407d6bf9-fd10-482b-b235-abc8bb04195c:  validate $param''');
    if (!sysParams.keys.contains(id)) {
      return ['Unrecognized param: $id. Allowed values: ${sysParams.keys}'];
    }
    return [];
  }
}

Map<String, SysParam> sysParams = {
  'out': SysParam(
      // {{dartrix.out}}
      name: 'out',
      abbr: 'o',
      docstring: 'Output directory.',
      help: 'Output directory, relative to current working directory.',
      typeHint: 'path',
      defaultsTo: './'),
  'package': SysParam(
      // {{dartrix.package}}
      name: 'package',
      abbr: 'p',
      docstring: 'pkg_name',
      help: 'Dart package name.',
      typeHint: '[_a-z][a-zA-Z0-9_]',
      defaultsTo: 'mypkg'),
  'ns': SysParam(
      // {{dartrix.ns}}
      name: 'ns',
      // abbr       : 's',
      docstring: 'Namespace',
      help: 'Namespace.',
      typeHint: 'segmented.string',
      defaultsTo: 'org.example'),
  'nsx': SysParam(
      name: 'nsx', // {{dartrix.nsx}}
      // abbr       : 'x',
      docstring: 'Namespace extension',
      help: 'Namespace extension; a namespace fragment to complement --ns.',
      typeHint: 'segmented.string'),
  'verbose': SysParam(
      name: 'verbose',
      abbr: 'v',
      docstring: 'Verbose output',
      help: 'Verbose output.',
      typeHint: 'bool',
      negatable: false,
      defaultsTo: 'false')
};

// enum Meta {template, plugin}
class MetaParam extends Configuration {
  // LibraryRef() : super.fromFile(File(fileName));
  final _types = ['template', 'plugin'];
  String type;
  String name;
  @override
  List<String> validate() {
    // print('''7f430023-a18f-4a3b-8439-8c865d911608:  validate meta: $type''');
    if (!(_types.contains(type))) {
      return ['Unrecognized type: $type. Allowed values: ${_types}'];
    }
    return [];
  }

  // void decode(dynamic anyValue) {
  //   if (anyValue is! String) {
  //     throw ConfigurationException(MetaParam, 'Param meta must be one of plugin or template');
  //   }

  //   try {
  //     meta = Meta.values.firstWhere((e) => e.toString() == 'Meta.' + anyValue);
  //   } catch(e) {
  //     if (e.message.startsWith('No element')) {
  //       Config.prodLogger.e('Invalid value for parameter meta: ${anyValue}.  Must be either \'template\' or \'plugin\'.');
  //     } else {
  //     }
  //   }
  // }
}

class Generic extends Configuration {
  Generic() : super();
  Param index;
  // String rewrite; // ?
}

class TemplateYaml extends Configuration {
  TemplateYaml(String fileName) : super.fromFile(File(fileName));

  String name;
  String description;
  String docstring;
  String version;
  @optionalConfiguration
  Params params;

  @optionalConfiguration
  String note;
  // @optionalConfiguration
  String dartrix;

  @optionalConfiguration
  MetaParam meta;

  @optionalConfiguration
  Generic generic;
}

class LibraryRef extends Configuration {
  // LibraryRef() : super.fromFile(File(fileName));

  String name;
  String path;
}

class UserYaml extends Configuration {
  UserYaml(String fileName) : super.fromFile(File(fileName));
  // UserYaml.fromFileName(String fileName) : super.fromFile(File(fileName));
  // UserYaml.fromFile(File f) : super.fromFile(f);

  List<LibraryRef> libraries;
}

Map loadYamlFileSync(String path) {
  var file = File(path);
  if (file?.existsSync() == true) {
    return loadYaml(file.readAsStringSync());
  }
  print('''addaece2-e72c-4d08-b6ca-ab4a9332d839:  ''');
  Config.ppLogger.w('loadYamlFileSync $path: not found');
  return null;
}

Future<Map> loadYamlFile(String path) async {
  //File
  var file = File(path);
  if ((await file?.exists()) == true) {
    return loadYaml(await file.readAsString());
  }
  return null;
}

Map getAppYaml() {
  var yaml = loadYamlFileSync(Config.appPkgRoot + '/pubspec.yaml');
  return yaml;
}

TemplateYaml getLibYaml(String templateRoot) {
  var config;
  var yamlFile = path.canonicalize(templateRoot + '/dartrix.yaml');
  try {
    config = TemplateYaml(yamlFile);
  } catch (e) {
    if (Config.debug) {
      Config.debugLogger.e(e);
    } else {
      Config.prodLogger.e('getLibYaml: $e');
      Config.prodLogger.e('bad file: $yamlFile');
    }
  }
  return config;
}

TemplateYaml getTemplateYaml(String tLib, String templateRoot) {
  // Config.debugLogger.d('getTemplateYaml $tLib, $templateRoot');
  //FIXME: memoize
  TemplateYaml config;
  var yamlFile = path.canonicalize(templateRoot + '/.yaml');
  // print('''a2ecca5c-6d24-4dc4-9aca-7738a2421a12: yamlFile $yamlFile'''');
  try {
    config = TemplateYaml(yamlFile);
  } catch (e) {
    if (e.message.startsWith('Cannot open file')) {
      print('''fb4f67f6-8035-486c-b94e-407cf7e85af0:  ''');
      Config.prodLogger.e(
          'Yaml file for template ${path.basename(templateRoot)} in lib $tLib not found. Each template must include a valid .yaml file.');
      return null;
    } else if (e.toString().startsWith('Invalid configuration data')) {
      Config.prodLogger.e(
          'getTemplateYaml: The .yaml file for template \'${path.basename(templateRoot)}\' in lib ${tLib} is corrupt: ${e.message}');
      return null;
    } else {
      if (Config.debug) {
        Config.debugLogger.e(e);
        // exit(1);
        return null;
      } else {
        Config.prodLogger.e('$e ${yamlFile}');
        return null;
      }
    }
  }
  Config.templateYaml = config; // memoize it
  return config;
}

UserYaml getUserYaml() {
  var userHome = Config.home + '/.dartrix.d';
  if (!verifyExists(userHome)) {
    if (Config.verbose) {
      Config.prodLogger.i(':home (~/.dartrix.d) not found)');
    }
    return null;
  }
  var userYaml;
  var userYamlPath = userHome + '/user.yaml';
  try {
    userYaml = UserYaml(userYamlPath);
  } catch (e) {
    if (e.message.startsWith('Cannot open file')) {
      if (Config.verbose) {
        Config.prodLogger
            .i(infoPen(':user config file: not found (${userYamlPath})'));
      }
      return null;
    } else {
      Config.prodLogger.e(severePen('$userYamlPath: ${e.message}'));
      // exit(1);
      return null;
    }
  }
  // if (Config.verbose) {
  //   Config.prodLogger.v(':user config file found at (${userHome}/user.yaml)');
  // }
  // print('NORMALIZING');
  userYaml.libraries.forEach((lib) {
    // print(lib.path);
    var libPath = path.canonicalize(userHome + '/' + lib.path);
    lib.path = libPath;
    // print(lib.path);
  });
  return userYaml;
}

UserYaml getLocalYaml() {
  var localHome = Config.local;
  if (!verifyExists(localHome)) {
    if (Config.verbose) {
      Config.prodLogger.i(':local (${localHome}) not found)');
    }
    return null;
  }
  // print('LOCAL: $localHome');
  var localYaml;
  var localYamlPath = localHome + '/local.yaml';
  // print('LOCAL YAML: $localYamlPath');
  try {
    localYaml = UserYaml(localYamlPath);
  } catch (e) {
    if (e.message.startsWith('Cannot open file')) {
      if (Config.verbose) {
        Config.prodLogger
            .i(infoPen(':local config file: not found (${localYamlPath})'));
      }
      return null;
    } else {
      Config.prodLogger.e(severePen('$localYamlPath: ${e.message}'));
      // exit(1);
      return null;
    }
  }
  // if (Config.verbose) {
  //   Config.prodLogger.v(':local config file found at (${localHome}/local.yaml)');
  // }
  // print('NORMALIZING');
  localYaml.libraries.forEach((lib) {
    // print(lib.path);
    var libPath;
    if (path.isRelative(lib.path)) {
      libPath = path.canonicalize(localHome + '/' + lib.path);
      lib.path = libPath;
    }
    // print(lib.path);
  });
  return localYaml;
}
