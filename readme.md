# zcanvas
A cross platform HTML Canvas implementation in Zig.

The pure Zig canvas backend is a work in progress and is far from complete and
has poor performance. Alternatively there is the Cairo backend which is faster
and more complete at the cost of being more heavyweight and relying on C which
requires linking the C standard library.

## Install Dependencies
```
sudo apt-get install libsdl2-dev
sudo apt-get install libcairo2-dev
```

## Build Demo
This project uses the jvbuild build system. Use `jvbuild run demo_cairo` or `jvbuild run demo_software` to run the cairo backed and software backed demos respectively.

## Rendering Output
zcanvas provides a window library based on SDL2 for rendering output to a
desktop window and handling input.

## API
The JS wrapper has the same API as a real HTML canvas context. The Zig version of the library due to being a staticly typed language has a few differences for example instead of `ctx.fillStyle = "#ffffff"` you must use `ctx.fillStyle = [_]u8{255, 255, 255, 255}` instead. Read
`docs.md` to view full Zig API.

## Shout out
Check out [NoBS Code](https://www.youtube.com/watch?v=hpiILbMkF9w) on YouTube.
They taught me the math required to render shapes.