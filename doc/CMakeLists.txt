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
    COMMAND ${CMAKE_COMMAND} -E echo "Running $<TARGET_FILE_NAME:factorial> ..."
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/factorial 1 2 3 4 5 > test1.log
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/factorial -Dt 3 2 > test2.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt test2.out > test2.log
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/factorial -Dd,t 3 > test3.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt test3.out > test3.log
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/factorial -Dd 4 > test4.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt -d result test4.out > test4.log
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/factorial -Dd 3 > test5.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt -t factorial -FL test5.out > test5.log
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/factorial -Dt,D=1000,g 3 > test6.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt test6.out > test6.log
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/src/lib
)

include(GNUInstallDirs)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/dbug.html TYPE DOC)

enable_testing()

# Define a function to simplify adding tests.
function(factorial nr)
  add_test(NAME factorial_${nr} COMMAND ${CMAKE_COMMAND} -E compare_files test${nr}.log test${nr}.ref )
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

