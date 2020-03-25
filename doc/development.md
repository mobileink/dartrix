# developing template libraries (plugins)

## terminology

* package: all the stuff in a package root directory
* package config: the list of its deps
** NB: each dep is also a pkg
* package uri: a uri of the form `package:foobar_dartrix`; NOT the
  file:// uri of its root directory. The package URI resolves to
  <root>/lib/, NOT <root>/ - the former is called the PkgUriRoot, the
  latter, the PkgRoot.
* package name: `foobar_dartrix`
* package root:  package name qua directory
* package uri root:  package_root/lib
* plugin name:  `foobar`

* app name  : `dartrix`
* app suffix: `_dartrix`

Dartrix is composed of several commands and a lib.  To distinguish between the dartrix app, cmds, and plugins:

* cmdPkg - the pkg for the command, by default always dartrix for each cmd
** resolveCmdPkgRoot(), etc
* pluginPkg


## packages and package configs

* Current Working Directory (cwd): dart:io/Directory.current
* Currently Running Dart Script (crds?): dart:io/Platform.script
* Current Isolate (cwi): Isolate.current
* Current Package URI (cpkg) = pkg root of cwi: Isolate.packageConfig (a URI)
* Package Root: the filesystem directory containing pubspec.yaml,
.packages, .dart_tool, and the `lib/` subdir.
* Package URI root: the `lib/` subdir of the package root.

The "package uri root" is what the package uri points to: the lib dir,
not the root dir.  So its the access root.

NOTE: File URIs look like `file:///foo/bar`; they have a .file getter,
which strips the `file://` scheme, giving `/foo/bar`

```
  Uri currentIsoPkgConfigUri = await Isolate.packageConfig;
  // e.g. file:///Users/gar/mobileink/dartrix/.packages
  _log.info("currentIsoPkgConfigUri: $currentIsoPkgConfigUri");

  // Isolate.packageConfig finds the version 1 .packages file;
  // use that to get the PackageConfig and you get the contents
  // of the version 2 .dart_tool/package_config.json
  // findPackageConfigUri is a fn in package:package_confg
  PackageConfig pkgConfig = await findPackageConfigUri(currentIsoPkgConfigUri);
  _log.info("current iso PackageConfig: $pkgConfig");
  if (debug.debug) debug.debugPackageConfig(pkgConfig);
```

The `PackageConfig` class models the contents of
`.dart_tool/package_config.json`.  Fields:

* name               : e.g. dartrix, package_config
* packageUriRoot     : file Uri of the /lib dir of the pkg
* root               : the filesystem root of the package

E.g. we're developing from ~/mobileink/dartrix. That's the "package
root" directory; it contains pubspec.yaml, .packages, .dart_tool, and
lib/. The lib subdir, `~/mobileink/dartrix/lib`, is the pkg "uri
root". That's because package uris like `package:dartrix` point to
that directory rather than the root directory.
