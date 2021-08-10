set(factorial_SRCS main.c factorial.c)

add_executable(factorial ${factorial_SRCS})

target_link_libraries(factorial dbug)

target_include_directories(factorial PUBLIC "${CMAKE_SOURCE_DIR}/src/lib")

find_program(PERL perl REQUIRED)

add_custom_target(doc ALL COMMAND ${PERL} -S pod2html --infile=${CMAKE_CURRENT_SOURCE_DIR}/dbug.pod --outfile=${CMAKE_CURRENT_BINARY_DIR}/dbug.html VERBATIM)

# On Windows you need to find the .dll just built by moving the working directory to the src/lib build dir.
add_custom_command(
    TARGET factorial
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo "Running $<TARGET_FILE:factorial> ..."
    COMMAND $<TARGET_FILE:factorial> 1 2 3 4 5 > ${CMAKE_CURRENT_BINARY_DIR}/test1.log
    COMMAND $<TARGET_FILE:factorial> -Dt 3 2 > ${CMAKE_CURRENT_BINARY_DIR}/test2.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt ${CMAKE_CURRENT_BINARY_DIR}/test2.out > ${CMAKE_CURRENT_BINARY_DIR}/test2.log
    COMMAND $<TARGET_FILE:factorial> -Dd,t 3 > ${CMAKE_CURRENT_BINARY_DIR}/test3.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt ${CMAKE_CURRENT_BINARY_DIR}/test3.out > ${CMAKE_CURRENT_BINARY_DIR}/test3.log
    COMMAND $<TARGET_FILE:factorial> -Dd 4 > ${CMAKE_CURRENT_BINARY_DIR}/test4.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt -d result ${CMAKE_CURRENT_BINARY_DIR}/test4.out > ${CMAKE_CURRENT_BINARY_DIR}/test4.log
    COMMAND $<TARGET_FILE:factorial> -Dd 3 > ${CMAKE_CURRENT_BINARY_DIR}/test5.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt -t factorial -FL ${CMAKE_CURRENT_BINARY_DIR}/test5.out > ${CMAKE_CURRENT_BINARY_DIR}/test5.log
    COMMAND $<TARGET_FILE:factorial> -Dt,D=1000,g 3 > ${CMAKE_CURRENT_BINARY_DIR}/test6.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt ${CMAKE_CURRENT_BINARY_DIR}/test6.out > ${CMAKE_CURRENT_BINARY_DIR}/test6.log
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/src/lib
)

include(GNUInstallDirs)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/dbug.html TYPE DOC)

enable_testing()

# Define a function to simplify adding tests.
function(factorial nr)
  add_test(NAME factorial_${nr} COMMAND ${CMAKE_COMMAND} -E compare_files --ignore-eol ${CMAKE_CURRENT_SOURCE_DIR}/test${nr}.ref test${nr}.log)
endfunction(factorial)

foreach(I RANGE 1 4)
  factorial(${I})
endforeach()

# Define a function to simplify adding tests.
function(factorial_rex nr)
  add_test(NAME factorial_rex_${nr} COMMAND ${PERL} ${CMAKE_CURRENT_SOURCE_DIR}/diffrex.pl ${CMAKE_CURRENT_SOURCE_DIR}/test${nr}.ref test${nr}.log)
endfunction(factorial_rex)

foreach(I RANGE 5 6)
  factorial_rex(${I})
endforeach()

