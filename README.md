# DBUG

This is DBUG, a Posix-threads debugging library.

DBUG itself consists of:
- the library (-ldbug)
- reporting tool dbugrpt
- the header dbug.h
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

In order to have an out-of-source build create a `build` directory first and configure from that directory:

```
$ mkdir build
$ cd build
$ ../configure
```

See file `INSTALL` for further installation instructions.

## DOCUMENTATION

[DBUG GitHub Pages](https://TransferWare.github.io/dbug/)
