set(factorial_SRCS main.c factorial.c)

add_executable(factorial ${factorial_SRCS})

target_link_libraries(factorial dbug)

target_include_directories(factorial PUBLIC "${CMAKE_SOURCE_DIR}/src/lib")

find_program(PERL perl REQUIRED)

add_custom_target(
  doc ALL
  COMMAND ${PERL} -S pod2html --infile=${CMAKE_CURRENT_SOURCE_DIR}/dbug.pod --outfile=${CMAKE_CURRENT_BINARY_DIR}/dbug.html
  VERBATIM
)

include(GNUInstallDirs)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/dbug.html TYPE DOC)

enable_testing()

# On Windows you need to find the .dll; copy it here
if ($<TARGET_RUNTIME_DLLS:factorial>)
  add_custom_command(
    TARGET factorial POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_RUNTIME_DLLS:factorial> $<TARGET_FILE_DIR:factorial>
    COMMAND_EXPAND_LISTS
  )
endif()

# Create output files to compare
add_custom_target(
    test ALL
    COMMAND ${CMAKE_COMMAND} -E echo "Creating test1.log"
    COMMAND $<TARGET_FILE:factorial> 1 2 3 4 5 > test1.log
    COMMAND ${CMAKE_COMMAND} -E echo "Creating test2.log"
    COMMAND $<TARGET_FILE:factorial> -Dt 3 2 > test2.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt test2.out > test2.log
    COMMAND ${CMAKE_COMMAND} -E echo "Creating test3.log"
    COMMAND $<TARGET_FILE:factorial> -Dd,t 3 > test3.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt test3.out > test3.log
    COMMAND ${CMAKE_COMMAND} -E echo "Creating test4.log"
    COMMAND $<TARGET_FILE:factorial> -Dd 4 > test4.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt -d result test4.out > test4.log
    COMMAND ${CMAKE_COMMAND} -E echo "Creating test5.log"
    COMMAND $<TARGET_FILE:factorial> -Dd 3 > test5.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt -t factorial -FL test5.out > test5.log
    COMMAND ${CMAKE_COMMAND} -E echo "Creating test6.log"
    COMMAND $<TARGET_FILE:factorial> -Dt,D=1000,g 3 > test6.out
    COMMAND ${PERL} ${PROJECT_SOURCE_DIR}/src/prog/dbugrpt test6.out > test6.log
    VERBATIM
)

# Define a function to simplify adding tests.
function(factorial nr)
  add_test(
    NAME factorial_${nr}
    COMMAND ${CMAKE_COMMAND} -E compare_files --ignore-eol ${CMAKE_CURRENT_SOURCE_DIR}/test${nr}.ref test${nr}.log
  )
endfunction(factorial)

foreach(I RANGE 1 4)
  factorial(${I})
endforeach()

# Define a function to simplify adding tests.
function(factorial_rex nr)
  add_test(
    NAME factorial_${nr}
    COMMAND ${PERL} ${CMAKE_CURRENT_SOURCE_DIR}/diffrex.pl ${CMAKE_CURRENT_SOURCE_DIR}/test${nr}.ref test${nr}.log
  )
endfunction(factorial_rex)

foreach(I RANGE 5 6)
  factorial_rex(${I})
endforeach()
