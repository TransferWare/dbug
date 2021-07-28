# DBUG

This is DBUG, a Posix-threads debugging library.

DBUG itself consists of:
- the library (-ldbug)
- reporting tool dbugrpt
- the header dbug.h

See INSTALL for installation instructions.

## MAINTAINER BUILD

This section is for maintainers only.
1. First download the code from the internet.
2. Install the following programs (if necessary):
   - automake
   - autoconf
   - libtool
3. On Cygwin also install
   - dos2unix
   - diffutils
   - libcrypt-dev
   - g++
4. Next on Cygwin issue: `$ dos2unix bootstrap`
5. Next the following command will generate all the machinery: `$ ./bootstrap`

## DOCUMENTATION

- doc/dbug.html

