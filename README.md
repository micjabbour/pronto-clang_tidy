# Pronto runner for clang-tidy

[![Code Climate](https://codeclimate.com/github/micjabbour/pronto-clang_tidy.png)](https://codeclimate.com/github/micjabbour/pronto-clang_tidy)
[![Build Status](https://travis-ci.org/micjabbour/pronto-clang_tidy.png)](https://travis-ci.org/micjabbour/pronto-clang_tidy)
[![Gem Version](https://badge.fury.io/rb/pronto-clang_tidy.png)](http://badge.fury.io/rb/pronto-clang_tidy)
[![Dependency Status](https://gemnasium.com/micjabbour/pronto-clang_tidy.png)](https://gemnasium.com/micjabbour/pronto-clang_tidy)

Pronto runner for [clang-tidy](http://clang.llvm.org/extra/clang-tidy), a clang-based C++ "linter" tool. [What is Pronto?](https://github.com/prontolabs/pronto)

This runner can be used after running clang-tidy on a codebase to submit the reported offences to web-based git repo managers (e.g. github, gitlab, ...) as comments using Pronto.

## Installation:

First, the following prerequisites need to be installed:

 1. clang-tidy
 2. Ruby
 3. Pronto, this can be done after installing Ruby using:
    ```
    gem install pronto
    ```
After that, pronto-clang_tidy can be installed using:
```
gem install pronto-clang_tidy
```
Pronto will look for clang-tidy output file and submit its contents as soon as this runner is installed.

## Configuration:

After configuring and running `clang-tidy` on your codebase, redirect and save its standard output to a file (e.g. `clang-tidy.out`).

To do that, you can use my [modified version of `run-clang-tidy.py`](https://gist.github.com/micjabbour/948578e0e24ce99aaaf6b32d848c9c18#file-run-clang-tidy-py) to automatically save clang-tidy output into `clang-tidy.out`:
```
python run-clang-tidy.py -checks=* -p build
```
where `build` is your build directory (that is, the directory that contains the generated file [`compile_commands.json`](https://clang.llvm.org/docs/JSONCompilationDatabase.html)).

The name of the clang-tidy output file can be configured by setting the environment variable `PRONTO_CLANG_TIDY_OUTFILE` prior to running pronto. If it is not set, the runner will assume the file name is `clang-tidy.out`.
