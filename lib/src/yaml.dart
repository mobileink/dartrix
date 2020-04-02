import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:safe_config/safe_config.dart';
import 'package:yaml/yaml.dart';

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/resolver.dart';
import 'package:dartrix/src/utils.dart';

// safe_config yaml classes
class ParamConfig extends Configuration {
  ParamConfig() : super();
  ParamConfig.fromFile(String fileName) : super.fromFile(File(fileName));
  ParamConfig.fromMap(Map m) : super.fromMap(m);

  String name;
  @optionalConfiguration
  String abbr;
  String docstring;
  @optionalConfiguration
  String help;
  // String typeHelp; // parser 'valueHelp'
  // @optionalConfiguration
  String type; // _plugin, _template, _out_prefix
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

enum Meta {template, plugin}
class MetaParam extends Configuration {
  // LibraryRef() : super.fromFile(File(fileName));
  Meta meta;
  void decode(dynamic anyValue) {
    if (anyValue is! String) {
      throw ConfigurationException(MetaParam, 'Param meta must be one of plugin or template');
    }

    try {
      meta = Meta.values.firstWhere((e) => e.toString() == 'Meta.' + anyValue);
    } catch(e) {
      if (e.message.startsWith('No element')) {
        Config.prodLogger.e('Invalid value for parameter meta: ${anyValue}.  Must be either \'template\' or \'plugin\'.');
      } else {
      }
    }
  }
}

class TemplateYaml extends Configuration {
  TemplateYaml(String fileName) : super.fromFile(File(fileName));

  String name;
  String description;
  String docstring;
  String version;
  @optionalConfiguration
  List<ParamConfig> params;
  @optionalConfiguration
  String note;
  // @optionalConfiguration
  String dartrix;
  @optionalConfiguration
  MetaParam meta;

  @optionalConfiguration
  String generic;
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
  //File
  var file = File(path);
  if (file?.existsSync() == true) {
    return loadYaml(file.readAsStringSync());
  }
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

TemplateYaml getTemplateYaml(String templateRoot) {
  // Config.debugLogger.d('getTemplateYaml $templateRoot');
  //FIXME: memoize
  TemplateYaml config;
  var yamlFile = path.canonicalize(templateRoot + '/.yaml');
  // print('yamlFile $yamlFile');
  try {
    config = TemplateYaml(yamlFile);
  } catch (e) {
    if (Config.debug) {
      Config.debugLogger.e(e);
      // exit(1);
      return null;
    } else {
      Config.prodLogger.e('$e ${yamlFile}');
      return null;
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
