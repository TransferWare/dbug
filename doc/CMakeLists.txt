set(factorial_SRCS main.c factorial.c)

add_executable(factorial ${factorial_SRCS})

target_link_libraries(factorial dbug)

target_include_directories(factorial PUBLIC "${CMAKE_SOURCE_DIR}/src/lib")

find_program(PERL perl REQUIRED)

add_custom_target(doc ALL COMMAND ${PERL} -S pod2html --infile=${CMAKE_CURRENT_SOURCE_DIR}/dbug.pod --outfile=${CMAKE_CURRENT_BINARY_DIR}/dbug.html VERBATIM)

include(GNUInstallDirs)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/dbug.html TYPE DOC)

enable_testing()

# define a function to simplify adding tests
function(factorial nr)
  add_test(NAME factorial_${nr} COMMAND ${PERL} ${CMAKE_CURRENT_SOURCE_DIR}/test-harness.pl ${CMAKE_CURRENT_BINARY_DIR} test${nr})
#  set_tests_properties(dbugtest_${nr} PROPERTIES PASS_REGULAR_EXPRESSION "test${nr} passed")
endfunction(factorial)

foreach(I RANGE 1 6)
  factorial(${I})
endforeach()

