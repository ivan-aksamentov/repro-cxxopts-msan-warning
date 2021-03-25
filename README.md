# repro-cxxopts-msan-warning

Reproduces Clang Memory Sanitizer warnings related to global variables in cxxopts 2.2.1. Reported to maintainers as <TODO>.

Clang Memory Sanitizer reports numerous warnings when trying to include `cxxopts.hpp` into the project. The simplest affected program is as follows:

```cpp
#include <cxxopts.hpp>

int main(int argc, char *argv[]) {}

```

If configured with `halt_on_error=0`, memory sanitizer produces 1942 warnings.

The first error is:

(it's more convenient to read from the bottom)

```
MSAN_OPTIONS="symbolize=1:halt_on_error=0" MSAN_SYMBOLIZER_PATH="/usr/bin/llvm-symbolizer" ./a.out
==14==WARNING: MemorySanitizer: use-of-uninitialized-value
    #0 0x4a1656 in std::ctype<char> const const& std::use_facet<std::ctype<char> const>(std::locale const&) /usr/bin/../lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/locale_classes.tcc:135:55
    #1 0x49d605 in std::__detail::_Scanner<char>::_Scanner(char const*, char const*, std::regex_constants::syntax_option_type, std::locale) /usr/bin/../lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/regex_scanner.tcc:62:16
    #2 0x49c86c in std::__detail::_Compiler<std::__cxx11::regex_traits<char> >::_Compiler(char const*, char const*, std::locale const&, std::regex_constants::syntax_option_type) /usr/bin/../lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/regex_compiler.tcc:77:7
    #3 0x49c2f3 in std::enable_if<__is_contiguous_iter<char const*>::value, std::shared_ptr<std::__detail::_NFA<std::__cxx11::regex_traits<char> > const> >::type std::__detail::__compile_nfa<std::__cxx11::regex_traits<char>, char const*>(char const*, char const*, std::__cxx11::regex_traits<char>::locale_type const&, std::regex_constants::syntax_option_type) /usr/bin/../lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/regex_compiler.h:183:14
    #4 0x49bf24 in std::__cxx11::basic_regex<char, std::__cxx11::regex_traits<char> >::basic_regex<char const*>(char const*, char const*, std::locale, std::regex_constants::syntax_option_type) /usr/bin/../lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/regex.h:759:15
    #5 0x49b9c3 in std::__cxx11::basic_regex<char, std::__cxx11::regex_traits<char> >::basic_regex<char const*>(char const*, char const*, std::regex_constants::syntax_option_type) /usr/bin/../lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/regex.h:505:4
    #6 0x49a8f1 in std::__cxx11::basic_regex<char, std::__cxx11::regex_traits<char> >::basic_regex(char const*, std::regex_constants::syntax_option_type) /usr/bin/../lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/regex.h:438:9
    #7 0x41eaef in __cxx_global_var_init.4 /src/cxxopts.hpp:474:30
    #8 0x41ee17 in _GLOBAL__sub_I_main.cpp /src/main.cpp
    #9 0x53801c in __libc_csu_init (/a.out+0x53801c)
    #10 0x7f10b7be703f in __libc_start_main (/lib/x86_64-linux-gnu/libc.so.6+0x2703f)
    #11 0x41ee5d in _start (/a.out+0x41ee5d)
```

Notice #7 is points to these global variables in `cxxopts.hpp:474:30`:

```cpp
    namespace
    {
      std::basic_regex<char> integer_pattern
        ("(-)?(0x)?([0-9a-zA-Z]+)|((0x)?0)");
      std::basic_regex<char> truthy_pattern
        ("(t|T)(rue)?|1");
      std::basic_regex<char> falsy_pattern
        ("(f|F)(alse)?|0");
    }

```

## Hypotheses

Global variables in C++ are considered a bad practice.

I assume that some code runs during static initialization (before `main()`, notice absence of main function and presence of `__cxx_global_var_init` in entry #7 in the call stack) which relies on these variables being initialized before it runs. However, these variables are not initialized at the time of execution.

Additionally, in projects where `cxxopts.hpp` is included into multiple C++ modules, it may lead to a problem called "static initialization order fiasco". 

A solution would be to avoid global variables and to enforce code execution order, either in constructor or in the `parse()` method. If this is difficult or impossible with the current code architecture, sometimes, a Singleton pattern can be used to preserve convenience of global variables, while enforcing order of execution.


## Reproduction

This repository contains an example program:

https://github.com/ivan-aksamentov/repro-cxxopts-msan-warning

It uses `cxxopts.hpp` version 2.2.1 copied from: https://github.com/jarro2783/cxxopts/blob/v2.2.1/include/cxxopts.hpp

You can reproduce the problem by installing Docker, Make and running:

```bash
git clone https://github.com/ivan-aksamentov/repro-cxxopts-msan-warning
cd repro-cxxopts-msan-warning
make

```

This will build docker container, build and run the example program inside the container (see `Dockerfile` and `Makefile`).

You can prevent memory sanitizer from listing all the warnings, by setting `halt_on_error=1` in `Makefile`. In this case it will stop on the first warning.


## References:

 - https://isocpp.org/wiki/faq/ctors#static-init-order
 - https://en.cppreference.com/w/cpp/language/siof
 - https://www.cs.technion.ac.il/users/yechiel/c++-faq/static-init-order.html
 - https://stackoverflow.com/questions/29822181/prevent-static-initialization-order-fiasco-c
 - https://stackoverflow.com/questions/335369/finding-c-static-initialization-order-problems


## License

[MIT](/LICENSE)

Copyright (c) 2021 Ivan Aksamentov
