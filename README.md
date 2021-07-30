# DBUG

This is DBUG, a Posix-threads debugging library.

DBUG itself consists of:
- the C library (-ldbug) and header dbug.h
- the reporting tool dbugrpt
- a Perl module pdbug.pm

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

You will find the documentation here:
- [doc/dbug.html](doc/dbug.html), the DBUG manual page

You can also have a look at [the DBUG GitHub Pages](https://TransferWare.github.io/dbug/).
