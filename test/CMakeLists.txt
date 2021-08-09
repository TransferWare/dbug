set(dbugtest_SRCS dbugtest.c)

add_executable(dbugtest ${dbugtest_SRCS})

target_link_libraries(dbugtest dbug)

target_include_directories(dbugtest PUBLIC "${PROJECT_SOURCE_DIR}/src/lib")
                          
enable_testing()

# define a function to simplify adding tests
function(dbugtest nr arg1 arg2 arg3 arg4 arg5 arg6)
  add_test(NAME dbugtest_${nr} COMMAND ./dbugtest test${nr} ${arg1} ${arg2} ${arg3} ${arg4} ${arg5} ${arg6})
  set_tests_properties(dbugtest_${nr} PROPERTIES PASS_REGULAR_EXPRESSION "test${nr} passed")
endfunction(dbugtest)

foreach(I RANGE 1 5)
  dbugtest(${I} "" "" "" "" "" "")
endforeach()
dbugtest(6 d,t,g,D=1000 d:t:g:D,1000 b c a d)
