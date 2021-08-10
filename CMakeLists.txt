cmake_minimum_required(VERSION 3.21)

# set the project name
project(dbug VERSION 6.0.0)

# specify the C++ standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED True)
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

include(CheckSymbolExists)
include(CheckIncludeFile)
check_include_file(assert.h HAVE_ASSERT_H)
check_symbol_exists(clock "time.h" HAVE_CLOCK)
check_symbol_exists(Delay "" HAVE_DELAY)
check_include_file(dmalloc.h HAVE_DMALLOC_H)
check_include_file(errno.h HAVE_ERRNO_H)
check_symbol_exists(ftime, "sys/timeb.h" HAVE_FTIME)
check_symbol_exists(getpid unistd.h HAVE_GETPID)
check_symbol_exists(getrusage "sys/param.h" HAVE_GETRUSAGE)
check_symbol_exists(sleep unistd.h HAVE_SLEEP)
check_include_file(stdarg.h HAVE_STDARG_H)
check_include_file(stdio.h HAVE_STDIO_H)
check_include_file(stdlib.h HAVE_STDLIB_H)
check_include_file(sys/param.h HAVE_SYS_PARAM_H)
check_include_file(sys/resource.h HAVE_SYS_RESOURCE_H)
check_include_file(sys/timeb.h HAVE_SYS_TIMEB_H)
check_include_file(sys/time.h HAVE_SYS_TIME_H)
check_include_file(time.h HAVE_TIME_H)
check_include_file(unistd.h HAVE_UNISTD_H)
check_include_file(varargs.h HAVE_VARARGS_H)

configure_file(config.h.in config.h)

add_subdirectory(src)
add_subdirectory(test)
add_subdirectory(doc)
