# diceroll

Simple diceroll game, inspired by OneLonelyCoder for learning Zig

## Ideas and basic usage you can find here

+ Build Systems
    - Multiple build options
    - Usage of vcpkg
    - Usage of external libraries
+ Working with C libraries
    - Using external dependencies `raylib`
+ Parsing Command Arguments
+ Lightweight CLI input reading
+ Random number generation
+ Working with Zig :)


## Building and dependencies

This project was tested on windows with current zig master `zig 0.9` version, but it _should_ build on other systems as well.

It depends on [Raylib](https://github.com/raysan5/raylib) library.

To build this toy app on windows prefered way, would be to grap vcpkg package manager and do: 

```batch
vcpkg install raylib:x64-windows
```

## Ziglang build steps

Below there is list of known `zig build <step>` steps:

* `install` -- will install executable to `./zig-out` folder
* `run` -- will build app and start cli version by default
* `run -- -t gui` -- start GUI version (`--` allow passing arguments to executable)
* `gui` -- start GUI version of app

## On Progress

There are still many unused pieces of code and `main.zig` is highly unorganized. I will clean it up, extending Gui version.