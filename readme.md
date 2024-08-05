# zcanvas
A cross platform HTML Canvas implementation in pure Zig.

## Origin
VExcess wanted to spawn a window and draw to it using the HTML Canvas API. He was 
unable to find such a library so he decided to create his own library from scratch.
Later, he discovered the `skia-canvas` npm library that does exactly 
what he wanted. Similarly, there is the `canvaskit-wasm` library for emulating the
canvas API in web assembly. This project was then rededicated to be the
HTML Canvas implementation for Zirconium browser.

## Use Anywhere
Because the library is written in Zig it can easily be used by Zig, C, and C++.
Since zcanvas is self standing and doesn't rely on external libraries it
can be compiled to run anywhere that LLVM supports including freestanding web assembly.

### Installation
View `build.zig` and `demo/demo.zig` to see example usage.

### Rendering Output
zcanvas only computes the graphics, but it does not render them. To render the
graphics import a third party library such as SDL via `sudo apt install libsdl2-dev`.
Then copy the `sdllib.c` and `sdllib.h` files into your project and follow the example
in demo to create an app window and render the canvas' drawing buffer to the window.

## API
The JS wrapper has the same API as a real HTML canvas context. The Zig version of the library due to being a staticly typed language has a few differences for example instead of `ctx.fillStyle = "#ffffff"` you must use `ctx.fillStyle = [_]u8{255, 255, 255, 255}` instead. Read
`docs.md` to view full Zig API.

## Build Demo
Build the demo using `zig build` then run `make run` to run the demo