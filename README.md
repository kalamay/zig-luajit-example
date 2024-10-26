# zig-luajit-example

Building requires a C-compiler (i.e. `cc`) and `make`.

Update dependencies:

```sh
git submodule update --init
```

Create a lua file to execute:

```sh
echo "print('hello zig')" > main.lua
```

Run the executable:

```sh
zig build run -- main.lua
```
