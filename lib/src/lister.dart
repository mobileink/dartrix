import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:dartrix/src/config.dart';
import 'package:dartrix/src/resolver.dart';
import 'package:dartrix/src/yaml.dart';

List<Map> listUserLib() {
  Config.debugLogger.d('listUserLib');
  var userHome = Config.home + '/.dartrix.d';
  var userTemplatesRoot = userHome + '/templates';
  if (verifyExists(userTemplatesRoot)) {
    return [
      {
        'name': ':user', //'dartrix',
        'version': null,
        'cache': 'user',
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
        Config.prodLogger.v(':user home not found ($userHome)');
      }
    }
    return [];
  }
}

List<Map> listUserLibs() {
  Config.debugLogger.d('listUserLibs');
  List<Map> userLibs = [];
  UserYaml userYaml = getUserYaml();
  if (userYaml != null) {
    userYaml.libraries.forEach((lib) {
        // var libPath = //path.normalize(userHome + '/' + lib.path);
        // print('user lib: ${lib.name} > ${lib.path}');
        var libYaml = getLibYaml(lib.path);
        userLibs.add({
            'name': lib.name,
            'version': libYaml.version,
            'docstring': libYaml.docstring,
            'uriType': 'path',
            'cache': null,
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

  TemplateYaml ty;
  List<Map> localTemplateSpecs = [];
  localTemplates.forEach((t) {
    // print('template path: ${t.path}');
    ty = getTemplateYaml(t.path);
    localTemplateSpecs.add({
      'name': path.basename(t.path),
      'version': ty.version,
      'docstring': ty.docstring,
      'cache': ':local',
      'rootUri': Uri.parse(t.path)
    });
  });

  return localTemplateSpecs;
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
        Config.prodLogger.v(':user home not found ($userHome)');
      }
    }
    return [];
  }
  var userTemplates = Directory(userTemplatesRoot).listSync();
  userTemplates.retainWhere((f) => f is Directory);

  TemplateYaml ty;
  List<Map> userTemplateSpecs = [];
  userTemplates.forEach((t) {
    ty = getTemplateYaml(t.path);
    userTemplateSpecs.add({
      'name': path.basename(t.path),
      'version': ty.version,
      'docstring': ty.docstring,
      'cache': ':user',
      'rootUri': Uri.parse(t.path)
    });
  });

  return userTemplateSpecs;
}

/// List all template libraries (plugins).
/// Searches user, local, syscache, and pubdev (opt-in)
Future<List<Map>> listPlugins(String suffix) async {
  // Config.debugLogger.d('listPlugins $suffix');

  var userLibs = listUserLibs();
  // Config.ppLogger.d('userLibs: $userLibs');
  // return userLibs;

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

  var pubDevPlugins = [];
  if (Config.searchPubDev) {
    pubDevPlugins = await getPubDevPlugins(null);
  }

  // Config.ppLogger.v('userPkgs: $userPkgs');
  // Config.ppLogger.v('pubDevPlugins: $pubDevPlugins');
  List<Map> allPlugins = List.from(pubDevPlugins);
  // print('allPlugins: $allPlugins');
  allPlugins.addAll(userLibs);
  allPlugins.addAll(sysPkgs);

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

  allPlugins = allPlugins.fold([], (prev, curr) {
    if (prev == null) {
      return [curr];
    } else {
      // print('prev: $prev');
      // print('curr: $curr');
      if (prev.any((e) =>
          (e['name'] == curr['name']) && (e['version'] == curr['version']))) {
        // print('REMOVING');
        return prev;
      } else {
        prev.add(curr);
        return prev;
      }
    }
  });

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
