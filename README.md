# DBUG

This is DBUG, a Posix-threads debugging library.

DBUG itself consists of:
- the C library (-ldbug) and header dbug.h
- the reporting tool dbugrpt
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

See file `INSTALL` for further installation instructions.

## DOCUMENTATION

You can generate HTML documentation by `$ make html` and then you will find this documentation:
- `doc/dbug.html`, the DBUG manual page

You can also have a look at [the DBUG GitHub Pages](https://TransferWare.github.io/dbug/).

## UTILITIES

These utilities will be installed by `$ make install`:
1. `dbugrpt` to process DBUG log files (see also the DOCUMENTATION)
2. `rf2dbug` to process a Robot Framework test execution result XML file and convert it to a DBUG log file

## DEVELOPMENT

The following tools can be installed for development:
- splint for `$ make lint`
