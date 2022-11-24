# Changelog

Copyright (C) 1999-2022 G.J. Paulissen 


All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Types of changes:
- *Added* for new features.
- *Changed* for changes in existing functionality.
- *Deprecated* for soon-to-be removed features.
- *Removed* for now removed features.
- *Fixed* for any bug fixes.
- *Security* in case of vulnerabilities.

Please see the [DBUG issue queue](https://github.com/TransferWare/dbug/issues) for issues.

## [6.1.0] -  2022-11-24

### Fixed

- [The Perl script dbugrpt does not run.](https://github.com/TransferWare/dbug/issues/3)
- [The Unix clock function calculates the CPU time, not the wall clock time.](https://github.com/TransferWare/dbug/issues/4)

## [6.0.0] -  2021-08-02

A new version on GitHub.

### Added

- GitHub Pages support
- README.md describes up to date installation instructions
- CHANGELOG.md describes releases found on [DBUG releases](https://sourceforge.net/projects/transferware/files/dbug/) and in files ChangeLog and NEWS
- Lint support

### Changed

- README now refers to README.md
- ChangeLog now refers to CHANGELOG.md
- NEWS now refers to CHANGELOG.md
- src/prog/dbugrpt.in does not have RCS keyword $Header$ anymore
- configure test for clock() first to conform to ISO C90
- Comparing test log file with a regular expression file used for test6 in doc

### Removed

- Support for Perl module pdbug de-activated

## [5.1.0]

### Added

- Added rf2dbug utility for creating dbug log file from Robot Framework output.xml files.

## [5.0.0] -  2018-08-19

### Changed

- Solved issues with Perl dbug not well distributed
- Solved compiler warnings

## [4.8.0] -  2016-05-03

### Added

- Added support for Cygwin 2.5.1 64 bit

## [4.7.0] - 2014-08-07

### Added

- Added support for Cygwin 1.7.x

## [4.6.1]

### Changed

- Autoconf upgrade
- make check fixed

## [4.6.0] - 2007-08-21

### Added

- make distcheck now works with or without the Perl pdbug library
- added M4 configuration file config/dbug.m4 to be used by projects which depend on dbug
- the installation for Cygwin will set CC to "gcc -mno-cygwin" (if not set already)

## [4.5.0] - 2007-08-07

### Changed

- Installing the Perl pdbug library can be disabled by using `$ configure --disable-pdbug`

## [4.4.0] - 2006-12-16

### Added

- The Perl pdbug library is added to the distribution

## [4.3.0] 

### Changed

- Solved build problems due to new versions of autoconf/automake/libtool

## [4.2.0]

### Changed

- [ 1174400 ] average is displayed wrongly by dbugrpt

## [4.1.0]

### Changed

- [ 1061551 ] Timing incorrect error

## [4.0.0] - 2004-03-15

### Changed

- LGPL license applied instead of GPL license

### Removed

- imake support obsoleted

## [3.1.0]

### Added

- Build DBUG in separate build environment
- GNU Programming Standards enforced (ChangeLog, NEWS, etc.)

### Changed

- make dist for imake and Autoconf separated

## [3.0.0]

### Changed

- Negative numbers for timing info solved. Sourceforge Request ID 679212
- Implement GNU build system

## [2.0.4]

### Added

- Oracle Universal Installer support added

## [2.0.3]

### Added

- Ability to save log files with the process id by using %p in the output file name, e.g. dbug options is "d,t,o=dbug.%p.log"

## [2.0.2]

### Changed

   Vanderlande Industries ProPro 051270-5222 solved.  This happens when
   linking on a Solaris platform when the GNU compiler is used to compile
   the DBUG library:

```
   Undefined first referenced symbol in file __eprintf
   /usr/local/src/dbug/lib/libdbug.a(dbug.o)
```

   This bug shows up on Solaris when assert() is used and define NDEBUG
   (which ignores assertions) is not defined.  Solution: either go to
   $DBUG_HOME/src/lib and execute

```
$ make EXTRA_DEFINES=-DNDEBUG clean depend all install
```

   as the last installation step.  The other solution is to specify
   -lgcc on the link command line (make EXTRA_LIBRARIES=-lgcc ...), because
   __eprintf is part of libgcc.a

## [2.0.1]

### Changed

- Vanderlande Industries ProPro 051270-5204 solved: calling dbug_print_start_ctx() (in DBUG_PRINT()) without a valid context resulted in a core dump

## [2.0.0]

### Changed

- Memory leak solved. Showed up when the last reference for an output file was deleted (during dbug_done)

## [1.6.7]

### Changed

- Solved BUS error core dump due to incorrect movement within a large array. Bug appeared when more than 100 functions were called in a session

## [1.6.6]

### Changed

- Library build configuration bug solved
- Opening a different file for another dbug thread caused an error. Solved now

## [1.6.5]

### Changed

- Solved configuration bug

## [1.6.4]

### Added

- Added support for Oracle Installer

## [1.6.3]

### Changed

- The function dbug_done and its variants unwind the call stack.  This is useful when
  a thread is cancelled and the thread cleanup routine does not know how
  large the debug stack was
- The dbug output printed the init line (containing #I#) twice when
  Posix threads was not used

## [1.6.2]

### Changed

- Bug solved in dbugrpt (user defined strings containing #D# are filtered well now)
- dbugrpt tool prints an empty line when debug context changes

## [1.6.1]

### Added

- DBUG_PRINT can be used without a function context (i.e. not within DBUG_ENTER/DBUG_LEAVE) 

## [1.6.0]

### Added

- Enable sharing of files between threads. The file is opened only once and locked when one thread tries to write to it
- Configuration support enhanced for (shared) libraries

## [1.5.2]

### Changed

- Various bugfixes 
- Allow threads to inherit from the parent debugging context by using DBUG_INIT( NULL, ... ) 

## [1.5.0]

### Added

The DBUG output contains now the GMT date/time and a sequence number. This
allows for sorting the output file.  The command sort <logfile> will sort a
file in the following order: by thread creation (unique between several runs),
by date/time, by sequence.  Thus sort makes it easy to get a clear picture of
all threads.

## [1.4.0]

### Added

- DBUG_RETURN and DBUG_VOID_RETURN are now available for backwards compatibility

### Changed

- DBUG_PRINT is now compatible with the original version, i.e. interface before 1.3.0 is restored

## [1.3.1]

### Changed

- The command make World does not clean anymore, so html files will not be deleted
- Long function names are displayed correctly now in profiling report (Perl reporting tool)
- Debug options strings uses options separated by comma's and arguments separated by an equal sign
- Arguments of an option are (optionally) separated by an equal sign (e.g. -#d,t,D=1000 or -#d,t,D1000)
- Value of make variable DBUGLIB now uses the $(DBUG_HOME)/lib path.
  Previously it used $(USRLIBDIR) or $(SHLIBDIR).
  The last values are project specific and cause errors for other projects depending on DBUG

## [1.3.0]

### Added

- Configuration file dbug.cf created for using DBUG in other imake projects
- Posix pthread support
- Separate Perl reporting tool

### Changed

- Interface changed

## [1.2.0]

### Changed

- Solved bug when printing floats/doubles in Windows

## [1.1.0]

### Changed

- Documentation updated
- Library updated with external C functions
- README updated

## [1.0.0] - 1999-05-01

For historical reasons, this is when I first started development with DBUG.
