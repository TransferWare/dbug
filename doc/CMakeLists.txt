set(factorial_SRCS main.c factorial.c)

add_executable(factorial ${factorial_SRCS})

target_link_libraries(factorial dbug)

target_include_directories(factorial PUBLIC "${CMAKE_SOURCE_DIR}/src/lib")
                          
enable_testing()

# define a function to simplify adding tests
function(factorial nr)
  add_test(NAME factorial_${nr} COMMAND perl ${CMAKE_CURRENT_SOURCE_DIR}/test-harness.pl ${CMAKE_CURRENT_BINARY_DIR} test${nr})
#  set_tests_properties(dbugtest_${nr} PROPERTIES PASS_REGULAR_EXPRESSION "test${nr} passed")
endfunction(factorial)

factorial(1)
factorial(2)
factorial(3)
factorial(4)
factorial(5)
factorial(6)

