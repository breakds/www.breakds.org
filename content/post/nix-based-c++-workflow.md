---
# Documentation: https://wowchemy.com/docs/managing-content/

title: "Nix Based C++ Workflow From Scratch"
subtitle: ""
summary: "An introduction and a template for setting up C++/CMake development project from scratch."
authors: [breakds]
tags: ["nix", "c++", "dev", "cmake"]
categories: ["nix", "dev"]
date: 2021-07-24T09:51:06-07:00
lastmod: 2021-07-24T09:51:06-07:00
featured: false
draft: false

# Featured image
# To use, add an image named `featured.jpg/png` to your page's folder.
# Focal points: Smart, Center, TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight.
image:
  caption: ""
  focal_point: ""
  preview_only: false

# Projects (optional).
#   Associate this post with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `projects = ["internal-project"]` references `content/project/deep-learning/index.md`.
#   Otherwise, set `projects = []`.
projects: []
---

If you are like me, you have probably already suffered a lot from
having your poject depend on libraries installed in your system (e.g.
libraries installed with `apt install`). The down side of having
system-wide dependencies is multi-fold but it can be summarized as
simple as:

1. It is not reproducible on another machine or another system.
2. It can potentially introduce serious conflicts between your multiple projects.
3. Installing system-wide dependencies might casue system-wide failure.

There are many solutions to this, among which I think
[Nix](https://nixos.org/) provides one of the cleanest approaches. In
this post I would like to share my setup and hope it can inspire the
others with the same need.

## What does this solution (and post) offer?

**First, during development time**, it provides a per project based
development environment that you can activate when you are working
that project. A development environment means:

1. All your dependent 3rd party libraries are available to your project.
2. The environment variables are set correctly for you.
3. The tools (executables) that you need during development time are
   available to you. This might includes the complier, the tools to
   run unit test, the database, etc.
   
**Second, for deployment or publishing**, it provides a way to package
your C++ library for the other projects to depend on. The other
projects can be one of yours, or other developers.

At the very beginning you might find there is a lot to configure. I
have put everything in [this
template](https://github.com/nixvital/nix-based-cpp-starterkit) so
that you can base your new project or existing project on that. Bear
with me and I will also explain in this post the configurations in
detail so that you understand how you can customize it to your needs.

## Create the Template Project

This explains how such a Nix-based C++ template project is created step by step.

### Let there be a `flake.nix`

The technology that powers the development environment is called
[nix-shell](https://nixos.org/manual/nix/unstable/command-ref/nix-shell.html).
Here I choose the [nix flakes](https://nixos.wiki/wiki/Flakes) fashion
and provide a nix-shell via the `devShell` inside a flake. To create a
basic `devShell`, we need a very minimal `flake.nix` at the root of your
repository.

```nix
{
  description = "A template for Nix based C++ project setup.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/21.05";

    utils.url = "github:numtide/flake-utils";
    utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs: inputs.utils.lib.eachSystem [
    "x86_64-linux" "i686-linux" "aarch64-linux" "x86_64-darwin"
  ] (system: let pkgs = import nixpkgs {
                   inherit system;
                 };
             in {
               devShell = pkgs.mkShell rec {
                 name = "my-c++-project";

                 packages = with pkgs; [
                   # Development Tools
                   llvmPackages_11.clang
                   cmake
                   cmakeCurses
                 ];
               };
             });
}
```

The above `flake.nix` offers a `devShell` that provides the basic tooling for your C++ project, the llvm C/C++ complier (in the package `llvmPackages_11.clang`) and CMake build system.

To verify that this flake is valid, run `nix flake show .`.

```bash
$ nix flake show .
$ nix flake show .
git+file:///path/to/your/project/nix-based-cpp-starterkit
└───devShell
    ├───aarch64-linux: development environment 'my-c++-project'
    ├───i686-linux: development environment 'my-c++-project'
    ├───x86_64-darwin: development environment 'my-c++-project'
    └───x86_64-linux: development environment 'my-c++-project'
```

It basically says that the flake offers `devShell` for the listed
platforms. To actually activate the `devShell`, run `nix develop`.
Inside the `devShell`, you will find the tools such as `clang`,
`clang++` and `cmake` are available to you, thanks to the above
`flake.nix`.

### Also check-in the `flake.lock`

Note that running the above commands it will generate a `flake.lock`
file. It is merely a json file locking the versions of flake inputs.
This is pretty much the same as `Cargo.lock` (if your are also a
[Rust](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html)
developer) and `yarn.lock` (if you are also a
[JavaScript](https://classic.yarnpkg.com/en/docs/yarn-lock/)
developer).

If `flake.lock` is present at the same place of your `flake.nix`, the
next time you run `nix flake show .`, `nix develop` or anything that
invokes the flake utility, it will respect the locked version in
`flake.lock`. This helps prevent

1. Accidentally upgrading some of your dependencies.
2. Re-building dependencies because of the accidental upgrade, which can sometimes be time consuming.

Therefore, it is recommended to check-in your `flake.lock` file as well. When you actually want to force update a particular inputs, e.g. `nixpkgs`, run

```bash
$ nix flake lock --update-input nixpkgs
```

### Environemnt Variables

You can set the values of environment variables so that once your
`devShell` is activated, the envrionment variables hold the desired
value. For example, if you use `bash`, I would usually set `PS1` to
something that clearly tells me I am in a `devShell`. To achieve that,
just add a `shellHook` in your `devShell` definition.

```nix
devShell = pkgs.mkShell rec {
  name = "my-c++-project";
  packages = with pkgs; [
    # Development Tools
    llvmPackages_11.clang
    cmake
    cmakeCurses
  ];
  shellHook = let
    icon = "f121";
  in ''
    export PS1="$(echo -e '\u${icon}') {\[$(tput sgr0)\]\[\033[38;5;228m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]} (${name}) \\$ \[$(tput sgr0)\]"
  '';
};
```

You can put more environment variable assignments or commands here in `shellHook` for your `devShell`.

### Add the first `.cc` file

You can find the code up to the end of this section [here](https://github.com/nixvital/nix-based-cpp-starterkit/tree/first-cpp-file).

Let's start to actually add a `.cc` file that compiles to an
executable. The C++ program `what_time.cc` is really simple.

#### what_time.cc
```c++
#include "absl/time/time.h"
#include "absl/time/clock.h"
#include "spdlog/spdlog.h"

int main(int argc, char ** argv) {
  absl::Time time = absl::Now();
  spdlog::info("Currently, the UTC time is {}",
               absl::FormatTime(time, absl::UTCTimeZone()));
  return 0;
}
```

Since we are going to use `CMake` to build our projects, we also need
to add the `CMakeLists.txt`. Though `CMakeLists.txt` is full of boiler
plate code, but making incremental changes to it isn't hard once you
have a working one. I based the CMake configuration on [ Clément
Grégoire's
boilerplate](https://github.com/Lectem/cpp-boilerplate/blob/master/CMakeLists.txt).
I am not going to talk about CMake in details in this post, but [An
Introduction to Modern
CMake](https://cliutils.gitlab.io/modern-cmake/) has a lot of
information in case you are interested.

Now with all that files in place, the repository look like below:

```bash
$ lsd --tree
 .
├──  cmake
│  └──  Config.cmake.in
├──  CMakeLists.txt
├──  flake.lock
├──  flake.nix
├──  LICENSE
├──  README.md
└──  src
   ├──  CMakeLists.txt
   └──  what_time.cc
```

Also note that `what_time.cc` depends on two 3rd party libraries,
[absl](https://github.com/abseil/abseil-cpp) and
[spdlog](https://github.com/gabime/spdlog). To introduce those 2
dependencies, we need to add them in **three** places.

1. In `flake.nix` add them to `devShell`'s package so that when you activate the development environment they are available.
   ```nix
   devShell = pkgs.mkShell rec {
     name = "my-c++-project";

     packages = with pkgs; [
       # Development Tools
       llvmPackages_11.clang
       cmake
       cmakeCurses
        # Build time and Run time dependencies
       spdlog
       abseil-cpp
     ];
   };               
   ```
2. In the top-level `CmakeLists.txt`, tell `CMake` to find them with
   `find_package`. This happens when you call `cmake` later to
   generate the `Makefile`. And if `cmake` is called after the
   `devShell` is activated, it should find them.
   
   ```cmake
   find_package(spdlog REQUIRED)
   find_package(absl REQUIRED)
   ```
3. Tell the linker to link the corresponding libraries when you set up
   the build target `what_time`.
   
   ```cmake
   add_executable(what_time)
   target_sources(what_time PRIVATE what_time.cc)
   target_link_libraries(what_time PRIVATE absl::time spdlog::spdlog)
   ```
   
Now you should be able to build the project from the root of the
project.

```bash
# Activate the development environment
$ nix develop
# By convention create a direcotry called "build"
$ mkdir build
$ cd build
# Run CMake to generate the Makefile
$ cmake ..
# Compile the project
$ make
# Find your program at build/src/what_time, and run it
$ src/what_time
[2021-07-24 15:15:08.344] [info] Currently, the UTC time is 2021-07-24T22:15:08.344380643+00:00
```

### Let there be unit tests!

You can find the code up to the end of this section
[here](https://github.com/nixvital/nix-based-cpp-starterkit/tree/library-with-unittest).

A simple library was added as `simple.h`.

```c++
#pragma once

namespace simple {

template <typename ValueType>
auto Add(const ValueType &a, const ValueType &b) -> ValueType {
  return a + b;
}

} // namespace toy
```

And because we are good developers, an unit test is added.

```c++
#include "src/simple.h"

#include "gtest/gtest.h"
#include "gmock/gmock.h"

TEST(SimpleTest, OnePlusOneEqualsTwo) {
  EXPECT_EQ(2, simple::Add(1, 1));
}
```

This of course means that we need to add a new development time
dependency, `gtest` ([Google Test
Framework](https://github.com/google/googletest)) in `flake.nix`
(`devShell`).

```nix
devShell = pkgs.mkShell rec {
  name = "my-c++-project";
  
  packages = with pkgs; [
    # Development Tools
    llvmPackages_11.clang
    cmake
    cmakeCurses

    # Development time dependencies
    gtest

    # Build time and Run time dependencies
    spdlog
    abseil-cpp
  ];
};
```

And the top-level `CMakeLists.txt` needs to know about `gtest` too.

```cmake
find_package(GTest REQUIRED)
include(GoogleTest)
enable_testing()
```

Note that we did add more than just `find_package`. The extra lines
are there to provide the super power of
[ctest](https://cmake.org/cmake/help/latest/manual/ctest.1.html). This
means that once we register our unit test with CMake like below:

(Note that `gtest_discover_tests` at the end)

```cmake
add_executable(simple_test)
target_sources(simple_test PRIVATE simple_test.cc)
target_link_libraries(simple_test PRIVATE simple gtest gmock gtest_main)
gtest_discover_tests(simple_test)    
```

we can now compile the program with `make` and run `ctest`.


```$
$ ctest
Test project /home/breakds/projects/nix-based-cpp-starterkit/build
    Start 1: SimpleTest.OnePlusOneEqualsTwo
1/1 Test #1: SimpleTest.OnePlusOneEqualsTwo ...   Passed    0.00 sec

100% tests passed, 0 tests failed out of 1

Total Test time (real) =   0.00 sec
```

In fact you can also use `ctest -R` to run only the matched test
cases.

### Package your library for publishing or deployment

As usual, you can find the code up to the end of this section
[here](https://github.com/nixvital/nix-based-cpp-starterkit/tree/installable-package).

Now we have finished our library, it's time to package it so that
other people can use it in their projects too.

The first thing to do is to specify the targets you want to expose to
others in the top level `CMakeLists.txt`. This is done by adding the
targets to one of the `install` commands.

```cmake
install(
    TARGETS what_time simple
    EXPORT ${PROJECT_NAME}_Targets
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
```

In our case we added an executable `what_time` and a library called
`simple`.

The user of the package is supposed to call `find_package` in
`CMakeLists.txt` of their project to use it as a dependency. Because
they also need to be able to find the dependencies of this package
itself, we need to notify them by adding all the runtime dependencies
in `cmake/Config.cmake.in`. This will become a `Config.cmake` file
after the packaging.

#### cmake/Config.cmake.in
```cmake
include(CMakeFindDependencyMacro)
find_dependency(spdlog REQUIRED)
find_dependency(absl REQUIRED)
```

Now, we can add the Nix derivation for our package as

```nix
{ lib
, llvmPackages_11
, cmake
, spdlog
, abseil-cpp }:

llvmPackages_11.stdenv.mkDerivation rec {
  pname = "cpp-examples";
  version = "0.1.0";
  
  src = ./.;

  nativeBuildInputs = [ cmake ];
  buildInputs = [ spdlog abseil-cpp ];

  cmakeFlags = [
    "-DENABLE_TESTING=OFF"
    "-DENABLE_INSTALL=ON"
  ];

  meta = with lib; {
    homepage = "https://github.com/nixvital/nix-based-cpp-starterkit";
    description = ''
      A template for Nix based C++ project setup.";
    '';
    licencse = licenses.mit;
    platforms = with platforms; linux ++ darwin;
    maintainers = [ maintainers.breakds ];    
  };
}
```

We can then set the `defaultPackage` of this flake to this derivation
in `flake.nix`.

```
devShell = { 
  ...
};
defaultPackage = pkgs.callPackage ./default.nix {};
```

To test that this actually produces the package after building, run

```
$ nix build
```

It will build the `defaultPackage` and put it in `/nix/store` while
also create a symbolic link to that built package called `result` in
the current directory.

```
$ lsd --tree result
 result ⇒ /nix/store/y1pxfrpwcn8lhncb6fk5kfyx7z2gzkqh-cpp-examples-0.1.0
├──  bin
│  └──  what_time
├──  include
│  └──  src
│     └──  simple.h
└──  lib
   ├──  cmake
   │  └──  cpp-example
   │     ├──  cpp-exampleConfig.cmake
   │     ├──  cpp-exampleConfigVersion.cmake
   │     ├──  cpp-exampleTargets-release.cmake
   │     └──  cpp-exampleTargets.cmake
   └──  libsimple.a
```

The package contains:

1. The binary `what_time`
2. The header `simple.h`
3. The (static) library `libsimple.a`
4. The customer facing cmake configurations

### Extra: How to use the package as a dependency in another project?

This is partially a repeat of the steps we did above:

1. Add the package of this project to `packages` of the other project's `devShell`.
2. Add `find_package(<PROJECT_NAME>)` in the other project's top-level `CMakeLists.txt`.
3. When needed, link the libraries to `<PROJECT_NAME>:<TARGET>`.

## Conclusion

The template is now hosted on [GitHub](https://github.com/nixvital/nix-based-cpp-starterkit). You can just click the green button `Use this template` to create your own awesome C++ project. Good luck!
