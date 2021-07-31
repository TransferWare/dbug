# DBUG

This is DBUG, a Posix-threads debugging library.

DBUG itself consists of:
- the C library (-ldbug) and header dbug.h
- the reporting tool dbugrpt
- a Perl module pdbug.pm
- a Robot Framework test execution result converter

## CHANGELOG

See the file [`CHANGELOG.md`](CHANGELOG.md).

## INSTALL FROM SOURCE

Also called the MAINTAINER BUILD. You just need the sources either cloned from [DBUG on GitHub](https://github.com/TransferWare/dbug) or from a source archive.

You need a Unix shell which is available on Mac OS X, Linux and Unix of course.
On Windows you can use the Windows Subsystem for Linux (WSL), Cygwin or Git Bash.

You need the following programs:
- automake
- autoconf
- libtool (on a Mac OS X glibtool)

On Cygwin you need also:
- diffutils
- libcrypt-dev
- g++

Next the following command will generate the Autotools `configure` script:

```
$ ./bootstrap
```

## INSTALL

Here you need either a distribution archive with the `configure` script or you must have bootstrapped your environment.

This help (`./confgure --help`) will show the following non-standard optional features:

```
  --enable-pdbug          install dbug for perl [default=no]
``` 

On the Mac you may need to invoke `configure` like this:

```
CFLAGS="-mmacosx-version-min=11.0" ./configure
```

to get rid of such a warning;

```
ld: warning: object file (../lib/.libs/libdbug.a(dbug.o)) was built for newer macOS version (11.0) than being linked (10.15)
```

See file `INSTALL` for further installation instructions.

## DOCUMENTATION

You can generate HTML documentation by:

```
$ make html
```

You will find the documentation here:
- [`doc/dbug.html`](doc/dbug.html), the DBUG manual page

You can also have a look at [the DBUG GitHub Pages](https://TransferWare.github.io/dbug/).

## UTILITIES

These files (all but the first created by `make`) may be useful:
1. `src/pdbug/pdbug.pm`, a Perl debugging module
2. `src/prog/dbugrpt` to process DBUG log files (see also the DOCUMENTATION)
3. `src/prog/rf2dbug` to read Robot Framework test execution result from an output XML file and output it to a DBUG log file

## DEVELOPMENT

The following tools can be installed for development:
- splint for `make lint`
