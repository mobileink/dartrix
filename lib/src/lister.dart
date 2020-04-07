import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/resolver.dart';
import 'package:dartrix/src/utils.dart';
import 'package:dartrix/src/yaml.dart';

// pkg= :dartrix | :user etc
Map listTemplate(String tLib, String tlibRoot, String template) {
  // Config.ppLogger.d('listTemplate $tLib, $tlibRoot, $template');
  if (!verifyExists(tlibRoot)) {
    if (Config.verbose) {
      Config.prodLogger.v('template lib root: not found ($tlibRoot)');
    }
    return {};
  }
  if (tLib == ':dartrix') {
  } else if (tLib == ':here') {
  } else if (tLib == ':user') {
  } else if (tLib == ':local') {
  } else {}

  var tPath = path.canonicalize(tlibRoot + '/templates/' + template);
  //TemplateYaml
  var yaml = getTemplateYaml(tLib, tPath);
  if (yaml == null) {
    exit(1);
  }
  var templateSpec = {
    'name': path.basename(tPath),
    'version': yaml.version,
    'docstring': yaml.docstring,
    'scope': 'home',
    'rootUri': tPath // Uri.parse(tPath)
  };

  return templateSpec;
}

// tLibKey one of :dartrix, :user, etc.
List<Map> listTemplates(String tLibKey) {
  var templatesRoot;
  switch (tLibKey) {
    case ':here':
      templatesRoot = '${Config.hereDir}/templates';
      break;
    case ':user':
      break;
    case ':local':
      break;
    case ':dartrix':
      templatesRoot = Config.dartrixHome;
      break;
    default: // plugin tlib
  }
  if (!verifyExists(templatesRoot)) {
    if (Config.verbose) {
      Config.prodLogger.v('${tLibKey} templates: not found ($templatesRoot)');
    }
    return [];
  }
  var templates = Directory(templatesRoot).listSync();
  templates.retainWhere((f) => f is Directory);

  //TemplateYaml
  var yaml;
  //List<Map>
  var templateSpecs = [];
  templates.forEach((t) {
    yaml = getTemplateYaml(tLibKey, t.path);
    if (yaml == null) {
      exit(1);
    }
    templateSpecs.add({
      'name': path.basename(t.path),
      'version': yaml.version,
      'docstring': yaml.docstring,
      'scope': 'home',
      'rootUri': Uri.parse(t.path)
    });
  });

  return templateSpecs;
}

List<Map> listHereTemplates() {
  // var hereHome = Config.home + '/.dartrix.d';
  var hereTemplatesRoot = '${Config.hereDir}/templates';
  if (!verifyExists(hereTemplatesRoot)) {
    if (Config.verbose) {
      Config.prodLogger.v(':here templates: not found ($hereTemplatesRoot)');
    }
    return [];
  }
  var hereTemplates = Directory(hereTemplatesRoot).listSync();
  hereTemplates.retainWhere((f) => f is Directory);

  //TemplateYaml
  var yaml;
  List<Map> hereTemplateSpecs = [];
  hereTemplates.forEach((t) {
    yaml = getTemplateYaml(':here', t.path);
    if (yaml == null) {
      exit(1);
    }
    hereTemplateSpecs.add({
      'name': path.basename(t.path),
      'version': yaml.version,
      'docstring': yaml.docstring,
      'scope': 'home',
      'rootUri': Uri.parse(t.path)
    });
  });

  return hereTemplateSpecs;
}

List<Map> listHereLib() {
  // Config.debugLogger.d('listHereLib');
  var hereTemplatesRoot = '${Config.hereDir}';
  // print('hereTemplatesRoot: $hereTemplatesRoot');
  if (verifyExists(hereTemplatesRoot)) {
    return [
      {
        'name': ':.', //'dartrix',
        'version': null,
        'docstring': 'Here templates',
        'scope': 'here',
        'rootUri': path.canonicalize(Config.hereDir)
      }
    ];
  } else {
    if (Config.verbose) {
      Config.prodLogger
          .v(':here (:.) template library not found (./.templates)');
    }
    return null;
  }
}

List<Map> listUserTemplates() {
  var userHome = Config.home + '/.dartrix.d';
  var userTemplatesRoot = userHome + '/templates';
  if (!verifyExists(userTemplatesRoot)) {
    if (verifyExists(userHome)) {
      if (Config.verbose) {
        Config.prodLogger.v(':user templates: not found ($userTemplatesRoot)');
      }
    } else {
      if (Config.verbose) {
        Config.prodLogger.v(':user not found ($userHome)');
      }
    }
    return [];
  }
  var userTemplates = Directory(userTemplatesRoot).listSync();
  userTemplates.retainWhere((f) => f is Directory);

  //TemplateYaml
  var yaml;
  List<Map> userTemplateSpecs = [];
  userTemplates.forEach((t) {
    yaml = getTemplateYaml(':user', t.path);
    if (yaml == null) {
      exit(1);
    }
    userTemplateSpecs.add({
      'name': path.basename(t.path),
      'version': yaml.version,
      'docstring': yaml.docstring,
      'scope': 'home',
      'rootUri': Uri.parse(t.path)
    });
  });

  return userTemplateSpecs;
}

List<Map> listUserLib() {
  // Config.debugLogger.d('listUserLib');
  var userHome = Config.home + '/.dartrix.d';
  var userTemplatesRoot = userHome + '/templates';
  if (verifyExists(userTemplatesRoot)) {
    return [
      {
        'name': ':user', //'dartrix',
        'version': null,
        'docstring': 'User templates',
        'scope': 'home',
        'rootUri': userHome
      }
    ];
  } else {
    if (verifyExists(userHome)) {
      if (Config.verbose) {
        Config.prodLogger.v(':user templates: not found ($userTemplatesRoot)');
      }
    } else {
      if (Config.verbose) {
        Config.prodLogger.v(':user not found ($userHome)');
      }
    }
    return [];
  }
}

List<Map> listUserLibs() {
  // Config.debugLogger.d('listUserLibs');
  List<Map> userLibs = [];
  //UserYaml
  var userYaml = getUserYaml();
  if (userYaml != null) {
    userYaml.libraries.forEach((lib) {
      // var libPath = //path.canonicalize(userHome + '/' + lib.path);
      // print('user lib: ${lib.name} > ${lib.path}');
      var libYaml = getLibYaml(lib.path);
      userLibs.add({
        'name': lib.name,
        'version': libYaml.version,
        'docstring': libYaml.docstring,
        // 'uriType': 'path',
        'scope': 'user',
        'rootUri': lib.path
      });
    });
  }
  // print('user libs: $userLibs');

  return userLibs;
}

List<Map> listLocalTemplates() {
  var localTemplatesRoot = Config.local + '/templates';
  if (!verifyExists(localTemplatesRoot)) {
    return [];
  }
  var localTemplates = Directory(localTemplatesRoot).listSync();
  localTemplates.retainWhere((f) => f is Directory);

  TemplateYaml yaml;
  List<Map> localTemplateSpecs = [];
  localTemplates.forEach((t) {
    // print('template path: ${t.path}');
    yaml = getTemplateYaml(':local', t.path);
    if (yaml == null) {
      exit(1);
    }
    localTemplateSpecs.add({
      'name': path.basename(t.path),
      'version': yaml.version,
      'docstring': yaml.docstring,
      'scope': 'local',
      'rootUri': Uri.parse(t.path)
    });
  });
  return localTemplateSpecs;
}

List<Map> listLocalLib() {
  // Config.debugLogger.d('listLocalLib');
  var localHome = Config.local;
  var localTemplatesRoot = localHome + '/templates';
  if (verifyExists(localTemplatesRoot)) {
    return [
      {
        'name': ':local', //'dartrix',
        'version': null,
        'docstring': 'Local templates',
        'scope': 'home',
        'rootUri': localHome
      }
    ];
  } else {
    if (verifyExists(localHome)) {
      if (Config.verbose) {
        Config.prodLogger
            .v(':local templates: not found ($localTemplatesRoot)');
      }
    } else {
      if (Config.verbose) {
        Config.prodLogger.v(':local not found ($localHome)');
      }
    }
    return [];
  }
}

List<Map> listLocalLibs() {
  // Config.debugLogger.d('listLocalLibs');
  List<Map> localLibs = [];
  //UserYaml
  var localYaml = getLocalYaml();
  // print('YAML: $localYaml');
  if (localYaml != null) {
    localYaml.libraries.forEach((lib) {
      // var libPath = //path.canonicalize(localHome + '/' + lib.path);
      // print('local lib: ${lib.name} > ${lib.path}');
      var libYaml = getLibYaml(lib.path);
      localLibs.add({
        'name': lib.name,
        'version': libYaml.version,
        'docstring': libYaml.docstring,
        // 'uriType': 'path',
        'scope': 'local',
        'rootUri': lib.path
      });
    });
  }
  // print('local libs: $localLibs');

  return localLibs;
}

/// List all template libraries (plugins).
/// Searches user, local, syscache, and pubdev (opt-in)
Future<List<Map>> listTLibs(String suffix) async {
  // Config.debugLogger.d('listTLibs $suffix');

  var userLibs = listUserLibs();
  // Config.ppLogger.d('userLibs: $userLibs');
  // return userLibs;

  List<Map> localLibs;
  if (Config.searchLocal) {
    localLibs = listLocalLibs();
  }

  // 2. syscache
  var sysPkgs = await searchSysCache(null); // find all
  // if (Config.verbose) {
  //   Config.debugLogger.i('Found in syscache: $sysPkgs');
  // }

  // var base;
  // var sysPkgs = [
  //   for (var dir in pkgDirs)
  //     {
  //       'name': path.basename(dir.path).split('-')[0],
  //       'rootUri': dir.path,
  //       'syscache': 'true'
  //     }
  // ];
  // if (sysPkgs != null) {
  //   userPkgs.addAll(sysPkgs);
  // }

  // DO NOT remove type annotation
  List<Map> pubDevPlugins = [];
  if (Config.searchPubDev) {
    pubDevPlugins = await getPubDevPlugins(null);
  }

  // Config.ppLogger.v('userPkgs: $userPkgs');
  // Config.ppLogger.v('pubDevPlugins: $pubDevPlugins');
  // DO NOT remove type annotation
  List<Map> allPlugins = List.from(pubDevPlugins);
  // print('allPlugins: $allPlugins');
  allPlugins.addAll(userLibs);
  if (Config.searchLocal) {
    allPlugins.addAll(localLibs);
  }
  allPlugins.addAll(sysPkgs);
  allPlugins.addAll(pubDevPlugins);

  // now remove pub.dev plugins that are already installed
  // allPlugins = allPlugins.fold([], (prev, elt) {
  //   var i = prev.indexWhere((e) => e['name'] == elt['name']);
  //   if (i < 0) {
  //     prev.add(elt);
  //   } else {
  //     if (prev[i]['rootUri'] == null) {
  //       // print('removing ${prev[i]}');
  //       prev.removeAt(i);
  //       prev.add(elt);
  //     }
  //   }
  //   return prev;
  // });
  // print('new allPlugins: $allPlugins');

  allPlugins.sort((a, b) {
    int order = a['name'].compareTo(b['name']);
    if (order == 0) {
      if (a['src'] == 'path') return -1;
      if (a['src'] == 'pubdev') return 1;
    }
    return order;
  });

  // retain only highest version
  // allPlugins = allPlugins.fold([], (prev, curr) {
  //   if (prev == null) {
  //     return [curr];
  //   } else {
  //     // print('prev: $prev');
  //     // print('curr: $curr');
  //     if (prev.any((e) =>
  //         (e['name'] == curr['name']) && (e['version'] == curr['version']))) {
  //       // print('REMOVING');
  //       return prev;
  //     } else {
  //       prev.add(curr);
  //       return prev;
  //     }
  //   }
  // });

  // if (userPkgs != null) {
  //   if (allPlugins != null) {
  //     return allPlugins;
  //   } else {
  //     return userPkgs;
  //   }
  // } else {
  return allPlugins;
  // }
}

List<Map> listBuiltinTemplates() {
  var builtinsTemplatesRoot = Config.builtinTemplatesRoot;
  // print('builtinsTemplatesRoot: $builtinsTemplatesRoot');
  if (!verifyExists(builtinsTemplatesRoot)) {
    if (verifyExists(builtinsTemplatesRoot)) {
      if (Config.verbose) {
        Config.prodLogger
            .v(':dartrix templates: not found ($builtinsTemplatesRoot)');
      }
    } else {
      if (Config.verbose) {
        Config.prodLogger.v(':dartrix not found ($builtinsTemplatesRoot)');
      }
    }
    return [];
  }
  var builtinsTemplates = Directory(builtinsTemplatesRoot).listSync();
  builtinsTemplates.retainWhere((f) => f is Directory);

  TemplateYaml yaml;
  List<Map> builtinsTemplateSpecs = [];
  builtinsTemplates.forEach((t) {
    // print(t);
    yaml = getTemplateYaml(':dartrix', t.path);
    // if (yaml == null) {
    //   exit(1);
    // }
    // if (yaml != null) {
    builtinsTemplateSpecs.add({
      'name': path.basename(t.path),
      'version': yaml.version,
      'docstring': yaml.docstring,
      'scope': 'dartrix',
      'rootUri': Uri.parse(t.path)
    });
    // } else {
    //   if (Config.debug) {
    //   Config.ppLogger.w(':dartrix template ${path.basename(t.path)} lacks .yaml file; ignoring.');
    // }
    // }
  });

  return builtinsTemplateSpecs;
}
