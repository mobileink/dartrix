# Dartrix - ALPHA version

An extensible template and tools command-line tool.  Dartrix comes
with a set of builtin templates to generate scripts, apps, libraries,
etc. in multiple languages. It also supports third-party template
libraries as "plugins".  A sample plugin is available at
[hello_dartrix](https://pub.dev/packages/hello_dartrix).

WARNING: This is an alpha version. A beta version will be available soon.

# Table of Contents
* [Getting Started](#getting_started)
* [Dartrix commands](#commands)
* [Plugins](#plugins)
    * [Third-Party](#third_party)
    * [Local](#local)
* [Developing Templates and Template Libraries](#dev)

## Getting Started <a name="getting_started"></a>

```
$ pub global activate dartrix
$ pub global run dartrix:list
$ pub global run dartrix:list dartrix
$ pub global run dartrix:man dartrix -t bashrc
$ pub global run dartrix:new -t bashrc -h
$ pub global run dartrix:new --dry-run -t bashrc
$ pub global run dartrix:new -t bashrc
$ cat ~/.dartrix
```

Aliases for `pub global run dartix:foo` are `dxfoo`, e.g. `dxlist`.

To use a different alias, create a `.dartrix` rc file with bash
aliases and source it from `~/.bashrc`:

```
$ dxnew dartrix bashrc -h
$ dxnew dartrix bashrc --prefix t
```

This will create `~/.dartrix` containing `alias tlist="pub global run
dartrix:list $@"` etc.

## Dartrix Commands <a name="commands"></a>

* list - print lists of template libraries and templates
* man - print manpages
* new - generate files from parameterized templates

For template development:

* sanity - verifies that all the standard bits are in place, paths are legal, etc.
* update - generate missing docstring files, manpages, and template handlers.

## Plugins - Template Libraries <a name="plugins"></a>

You can use third-party template libraries or create your own by
adding them as a dependencies in a project `pubspec.yaml` file.

The drawback of this is that you can only use such tools in the
projects where they are explicitly listed. This is the way Dart/Pub
tooling works.

Dartrix was written in part to address this issue of the
project-dependency of tooling. You can use Dartrix templates anywhere;
they have no dependency on project pubspec files. Dartrix uses the
standard practice of using a user-specific configuration file stored
as a dotfile in the $HOME directory.

### Third-Party  <a name="third_party"></a>

Steps to install a template library, say `foobar_dartrix`:

1. Create `~/.dart.d/pubspec.yaml`
2. Add a dependency to the library in the pubspec file.
3. Run `$ pub get` in `~/.dart.d`

The library should now be available to Dartrix tools.  Verify this by
running `dartrix:list`; you should see the installed library in the
list of available libraries.

### Local  <a name="local"></a>


You can easily develop and use plugins locally. Just follow the above
procedure, but list your local plugins using `path:` syntax. E.g.

```
dependencies:
  mytemplates_dartrix:
    path:../mytemplates_dartrix
```

## Developing Templates and Template Libraries <a name="dev"></a>

Start by using the builtin `template_library` template to create a
Dartrix template library package.

Detailed instructions for template development are provided in the
manpages.  The basic rules are:

* The package, the root directory of the package, and the main dart
file must be named by the package name suffixed by "_dartrix".  For
example, a library `foobar` should look like this:

```
foobar_dartrix/
    lib/foobar_dartrix.dart
    pubspec.yaml   # with "name: foobar_dartrix
```

* The file `lib/foobar_dartrix.dart` must contain a `main` entry point
  that handles template requests.
* Template files are written in the
  [{{mustache}}](https://mustache.github.io/) syntax, have a `.mustache`
  extension, and are stored in `templates/`, under the appropriate
  <template-name> subdirectory. In other words, each "template" may
  consist of multiple template files (and non-template assets, which
  are just coppied) organized under the template name.
* Optional but strongly recommended
  * Template `handlers` construct the data map and pass it back to
    Dartrix for merging with the template. Template handler code
    should go in `lib/src` and be organized by template, e.g. the
    handler for template `foo` should be in `lib/src/foo.dart`.  It
    would be called from the `main` routine in
    `lib/foobar_dartrix.dart`.
  * Docstrings, stored in `templates/` in files with the same name
    as the template but with suffix `.docstring`. A docstring file
    should contain a brief description of the template it documents,
    suitable for display by the `dartrix:list` command.
  * Manpages, stored in `man/`.  A manpage should be provided for
    the library itself and for each template it contains, with
    corresponding names suffixed by `.1`.  Manpages should provide
    detailed documentation.

Dartrix contains builtin templates and manpages for each of these
artifact types.  The `dartrix:update` command will inspect the list of
templates in a project and generate missing docstring files, manpages,
and handler code.

For example, if library `foobar_dartrix` contains templates `foo` and
`bar`, it will look like this:

```
foobar_dartrix/
  lib/foobar_dartrix.dart
  lib/src/foo.dart
  lib/src/bar.dart
  man/foo.1
  man/bar.1
  templates/foo/   # contains foo templates and assets
  templates/foo.docstring
  templates/bar/   # contains bar templates and assets
  templates/bar.docstring
  pubspec.yaml
```

The mechanism is simple: when the user asks for a plugin, Dartrix will
search the list of installed plugins (in `~/.dart.d/.packages`, which
is generated by `pub get` from `pubspec.yaml`), and then `spawn` the
selected package, passing the user's args to its `main` routine.  The
plugin's job is to construct a data map providing values for the
template and pass it back to Dartrix. Dartrix will then instantiate
the template.


