# DBUG - debugging for C and Oracle PL/SQL

[DBUG](https://github.com/TransferWare/dbug) provides a debugging library for C and Oracle PL/SQL.

You can install either part or both: they do not depend on each other.

## for C

The C library is a Posix-threads compliant debugging library for C.

It consists of:
- the C library (`-ldbug`) and header `dbug.h`
- the reporting tool `dbugrpt`
- a Robot Framework test execution result converter `rf2dbug`

## for PL/SQL

The PL/SQL library has a plug and play architecture to enable different output channels, i.e. other packages you may want to use like DBMS_OUTPUT.

The following output channels are available:
- DBMS_OUTPUT
- DBMS_APPLICATION_INFO
- PROFILER
- [LOG4PLSQL](http://sourceforge.net/projects/log4plsql) 

Follow these installation steps:

| Step | When |
| :--- | :--- |
| [DATABASE INSTALL](#database-install) | When you want to use it in your Oracle database  |
| [INSTALL FROM SOURCE](#install-from-source) | When you want the install the rest (not the database) from source |
| [INSTALL](#install) | When you want the install the rest and you have a `configure` script |

## CHANGELOG

See the file [CHANGELOG.md](CHANGELOG.md).

## DATABASE INSTALL

This section explains how to install just the PL/SQL library.

### Preconditions

You need to install [LOG4PLSQL](https://sourceforge.net/projects/log4plsql/) first. Running the 
`<LOG4PLSQL_HOME>/sql/install_log_user/install.sql` SQL*Plus script is sufficient for simple
logging to a table TLOG. Have a look at its documention file `<LOG4PLSQL_HOME>/index.html`.

### Installation

There are two methods to install the PL/SQL library:
1. use the [Paulissoft Application Tools for Oracle (PATO) GUI](https://github.com/paulissoft/pato-gui)
with the pom.xml file from the project root and schema ORACLE_TOOLS as the owner
2. execute `src/sql/install.sql` connected as the owner using SQL*Plus, SQLcl or SQL Developer

The advantage of the first method is that your installation is tracked and
that you can upgrade later on.

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

Issue this to (re-)generate the documentation:

```
$ make html
```

In the build directory you will find these files now:
- `src/sql/dbug_trigger.html`
- `src/sql/dbug.html`
- `util/dbug_trigger.html`
- `util/dbug_pls.html`
- `util/dbug_trigger_show.html`

You can also have a look at [the DBUG GitHub Pages](https://TransferWare.github.io/dbug/).

## UTILITIES

These utilities will be installed by `$ make install`:
1. `dbugrpt` to process DBUG log files (see also the DOCUMENTATION)
2. `rf2dbug` to process a Robot Framework test execution result XML file and convert it to a DBUG log file

## DEVELOPMENT

The following tools can be installed for development:
- splint for `$ make lint`
