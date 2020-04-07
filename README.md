# Dartrix ToolSuite (beta)

An extensible templates and tools.  Dartrix comes with a set of
builtin templates to generate scripts, apps, libraries, etc. in
multiple languages. It also supports third-party template libraries as
"plugins".  Several sample plugins are available; see below for
details.

WARNING: This is a beta version. It is not compatible with previous
alpha versions. If you wrote templates using previous versions you'll
need to make some minor changes as described below.  Windows users: it
probably won't work, but it's on my TODO list. Linux users: it ought
to work, but has only been tested on a Mac. Bug reports welcome.

NEW: This version adds support for automatic installation of plugins
from pub.dev, meta-templates, generic templates, predefined scopes and
libraries :here, :user, :local, and :dartrix, and a --Y parameter that
tells Dartrix to copy a template verbatim.

# Table of Contents
* [Getting Started](#getting_started)
* [Dartrix Template Libraries](#tlibs)
    * [Available Libraries](#available)
    * [Plugin Installation](#install)
* [Dartrix commands](#commands)
* [Plugins](#plugins)
    * [Third-Party](#third_party)
    * [Local](#local)
* [Developing Templates and Template Libraries](#dev)

## Getting Started <a name="getting_started"></a>

```
$ pub global activate dartrix
$ pub global run dartrix:list
## use 'dts'-prefixed aliases
$ dtslist
$ dtslist :d  # = :dartrix library
$ dtsnew :d bashrc --help
$ dtsnew --dry-run :d bashrc
$ dtsnew :d bashrc
```

Aliases for `pub global run dartix:foo` are `dtsfoo`, e.g. `dtslist`, `dtsnew`.

To use a different alias, create a file with bash
aliases and source it from `~/.bashrc`:

```
$ dtsnew :d bashrc --help
$ dtsnew :d bashrc --prefix t
```

This will create `./bashrc` containing lines of the following form:

```
alias tlist="pub global run --enable-asserts dartrix:list $@"
```

## Dartrix Template Libraries <a name="tlibs"></a>

Predefined:

* :. (:here) - any current working directory containing `./.dartrix.d/templates` counts as a "here" library.  Passing ':.' to a command will cause it to look only in the current working directory, e.g. `dtsnew :. foo` will instantiate the foo template in the current working directory (that is, `./.dartrix/templates/foo`).  This allow you to override installed templates, for example.
* :u (:user) - defaults to `~/.dartrix.d/templates`
* :l (:local) - defaults to `/usr/local/share/dartrix/templates`
* :d (:dartrix) - Dartrix built-in templates

All other library tags will resolve to plugin libraries.  Tag `:foo` will resolve to library (Dart package) `foo_dartrix`.

### Available Libraries <a name="available"></a>

At time of writing there are three libraries available on pub.dev:

* [hello_dartrix](https://pub.dev/packages/hello_dartrix) is a library
  of templates that generate Hello World code for a variety of
  programming languages.

* [dart_dartrix](https://pub.dev/packages/dart_dartrix) is a library of templates that generate Dart code.

* [flutter_dartrix](https://pub.dev/packages/flutter_dartrix) is a library of teplates the generate Flutter code.

At the moment these libraries only contain a few simple templates;
more will be added in coming weeks.  If you develop a template that
you think belongs in one of them, plus submit a ticket to the
appropriate Github repo.

### Plugin Installation <a name="install"></a>

Plugin libraries may be registered in three places. Libraries
downloaded and installed from pub.dev are ordinary dart packages; they
get installed in the syscache (~/.pub-cache). Users can also install
plugins for private use or for sharing on a local multi-user system.
You might want to do this during template development, or if your
templates contain proprietary information.

Template libraries (plugins) published on pub.dev are automatically
installed on first use.  Use the `dtslist` command with the `-p
(--pubdev)` parameter to see a list of available plugins (example
below). This will list them but not install them. If you list the
contents of a plugin it will be downloaded and installed (to
~/.pub-cache) automatically. Same thing if you use `dtsnew` on it.

User-scoped libraries are registered in `~/.dartrix.d/user.yaml`, as
shown below. Use of this is optional.

```
libraries:
  - name: foo_dartrix
    path: path/to/foo_dartrix
  - name: bar_dartrix
    path: path/to/bar_dartrix
```

Local-scoped libraries are registered similarly in
`/usr/local/share/dartrix/local.yaml`. Use of this is optional.

The location of these libraries will be configurable in a future version.

NOTE the distinction between the `:user` library and libraries in
"user scope". The latter are the libraries registered in
`~/.dartrix.d/user.yaml`, plus :user (`~/.dartrix.d/templates`).  The
same distinction holds between the `:local` library and libraries in
"local scope".

In general you will only need to use user scoped libraries, and the
:here library, when you are developing templates.

Local libraries are intended for sharing templates on multi-user systems. The list command by default ignores local scope; to enable it pass the `-l (--local)` flag.

#### Resolving template references

If one of the predefined library tags is used, Dartrix will look in
that library only. For plugins Dartrix will search the local Dart syscache
(`~/.pub-cache`) for a matching package.


## Dartrix Commands <a name="commands"></a>

* list - print lists of template libraries and templates
* man - print manpages
* new - generate files from parameterized templates

For template development:

WARNING: these commands are still under development.

* lint - verifies that all the standard bits are in place, paths are legal, etc.
* update - generate missing docstring files, manpages, and template handlers.

### List

The `list` command lists available template libraries and templates.

Sample output for `$ pub global run dartrix:list --pubdev`:

```
$ tlist --pubdev --local
dartrix:list, version 0.1.0

  Library       Version       Description
  :dartrix      0.2.0         builtin templates
  :here         [not used]    Here templates (./.dartrix.d/templates)
  :user                       User templates (~/.dartrix.d/templates)
  :local                      Local templates (/usr/local/share/dartrix/templates)
  --------
 +:dart         0.2.2         A Dartrix template library of Dart code.
                              path: /Users/gar/mobileink/dart_dartrix
 >:dart         0.2.2         Dartrix template plugin package.  Contains templates for Dart apps, libraries, packages, etc.
 ^:dart         0.2.2         Dartrix template plugin package.  Contains templates for Dart apps, libraries, packages, etc.
 *:flutter      0.2.0         A Dartrix template library of Flutter code.
                              path: /Users/gar/mobileink/flutter_dartrix
 +:flutter      0.2.0         A Dartrix template library of Flutter code.
                              path: /Users/gar/mobileink/flutter_dartrix
 >:flutter      0.1.0         Dartrix template plugin package.  Contains templates for Flutter code - apps, packages, plugins, widgets, etc.
 ^:flutter      0.1.0-beta    Dartrix template plugin package.  Contains templates for Flutter code - apps, packages, plugins, widgets, etc.
 *:hello        0.2.0         A Dartrix template library of Hello World demos.
                              path: /Users/gar/mobileink/hello_dartrix
 +:hello        0.2.0         A Dartrix template library of Hello World demos.
                              path: /Users/gar/mobileink/hello_dartrix
 ^:hello        0.1.0         Dartrix template plugin package.  Contains templates for "Hello World" in various programming languages.

*User  +Local  >Sys  ^pub.dev
```

In this example, package `hello` is listed three times:

* Version 0.1.0 was published to pub.dev
* Version 0.2.0 is registered in Local scope
* Version 0.2.0 is also registered in User scope.

In this case, the same code, in `$HOME/dartrixdev/hello_dartrix`, is
registered as a plugin in both User and Local scopes. This is just for
demo purposes, normally you probably would not do that.

### new

The `dtsnew` command instantiates a template.

#### the --here parameter

This parameter tells Dartrix to write the output to
`./.dartrix.d/templates`. It only applies for meta-templates, and when
--Y is used.  This makes the results available in the :here library,
which is useful if you want to begin developing a template but not a
template library. Use a meta-template to generate a template in :here,
and then edit it and use `dtxnew :. mytemplate` to use it.

Use --here in conjunction with --Y to modify any template.

#### the --Y parameter

The --Y parameter tells the `dtsnew` command to copy the template
verbatim.  It's named after the Y combinator, since you can think of
it as finding a fixed point.

This allows you to easily copy and modify any template.

## Plugins - Template Libraries <a name="plugins"></a>

## Developing Templates and Template Libraries <a name="dev"></a>

Detailed instructions for template development are (well, will be)
provided in the manpages.  The basic rules are:

* The package, the root directory of the package, and the main dart
file must be named by the package name suffixed by "_dartrix". The
root directory must contain a `dartrix.yaml` file that describes the
library. Each template is represented by a subdirectory under the
`templates/` subdir, and must contain a `.yaml` file.  For example, a
library `foobar` containing two templates, foo and bar, should look
like this:

```
foobar_dartrix/
    lib/foobar_dartrix.dart
    pubspec.yaml   # with "name: foobar_dartrix
    templates/
        foo/
          .yaml
          filea.mustache
        bar/
          .yaml
          fileb.mustache
```

* The file `lib/foobar_dartrix.dart` may be omitted if you do not plan
  to publish your library to pub.dev.  It's only there because pub.dev
  wants to see it.
* Templates in the library are represented by subdirectories of templates/
* Template files are written in the
  [{{mustache}}](https://mustache.github.io/) syntax, have a `.mustache`
  extension, and are stored in `templates/`, under the appropriate
  <template-name> subdirectory. In other words, each "template" may
  consist of multiple template files (and non-template assets, which
  are just coppied) organized under the template name.
* A library should contain manpages, stored in `man/`.  A manpage
  should be provided for the library itself and for each template it
  contains, with corresponding names suffixed by `.1`.  Manpages
  should provide detailed documentation.

Example of a `dartrix.yaml` file:

```
name        : mylib
version     : 0.2.2
docstring   : Short description of lib
description : More detailed description of lib
dartrix     : 0.2.0
```

An example of a template `.yaml` file:

```
name         : cmd_shell
version      : 0.2.1
docstring    : Dart command shell app
description  : A template for a command shell application.
dartrix      : 0.2.0   # version used to develop this template
params:
  sys:  # these are predefined parameters
    - id : package
      defaultsTo : myshell
    - id: out
      defaultsTo : <<package>>
  user:
    - name       : 'homepage'
      abbr       : 'w'
      docstring  : 'cmd prefix'
      defaultsTo : 'https://example.org/myapp'
      typeHint   : 'URL'
      help       : 'Homepage for app.'
```

Use the --Y parameter to copy any template and inspect its .yaml files.

### hidden and private parameters

Hidden parameters are available for use but not described in the help
screen; they are marked by property hidden: true.  Private parameters
are not exposed to the user at all; they provide a mechanism by which
the template author can initialize template data without
programming. They are indicated by property private: true.


### path rewriting

Dartrix supports path rewriting.  For a simple example see the `java`
template in the `hello_dartrix` plugin.  The general idea is that path
segments in upper case will be rewritten.

To indicate that a parameter should be used in path rewriting, use the
'seg' property, e.g. 'seg: FOO' will cause path segments named FOO in
the template source to be rewritten to the value of the parameter so
annotated.

Uppercase segments with leading underscores are reserved.

### predefined parameters

A small number of parameters are predefined to fit the most common use
cases:

* ns - a namespace, in segmented.string format.  The value of this parameter sets the following data fields, which become available in the template and for path rewriting:

  * {{dartrix.ns}}

  * _NS - the ns with '.' replaced by '/', for use in path rewriting

* nsx - namespace extension. This allows you to break a namespace into
  parts. For examle, org.acme.foo.bar could be treated as a namespace,
  or it could be broken into an ns part (org.acme) and an nsx part
  (foo.bar).  Generates:

  * {{dartrix.nsx}}

  * _NSX  - nsx with '.' replaced by '/', for path rewriting

* out - output path relative to current working directory. This makes
it easy to give the user the option of controlling the output path.  Generates:

  * {{dartrix.out}}

  * _OUT

### tricks

Sometimes you want to print something, e.g. punctuation, only if a key
has a value.  For example, a namespace extension must be preceded by a
dot; if the extension is null, the dot should be omitted.

A little mustache trickery takes care of this. Surround the output with a mustache "section", which will act as a conditional.  For example:

```
{{#dartrix.nsx}}.{{dartrix.nsx}}{{/dartrix.nsx}}
```

This will print nothing unless dartrix.nsx has a value other than
false, in which case it will print the '.' followed by the dartrix.nsx
value.  Dartrix will set the value to false if you do not set a
default value or if you set it to the empty
string ''  (using `defaultsTo`).

See the `java` template of library `hello_dartrix` for an example.
