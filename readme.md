# zig-html-canvas
A cross platform HTML Canvas implementation in pure Zig. I was wanting to be 
able to spawn an X11 window and draw to it using the HTML Canvas API. I was 
unable to find such a library so I decided to create my own library from scratch.
Later however, I discovered the `skia-canvas` npm library that does exactly 
what I wanted. Similarly, there is the `canvaskit-wasm` library for emulating the
canvas API in web assembly. 

Although I found libraries that satisfy my original use case, I already started
this project so I am going to continue it so that I can create a web browser
written entirely in Zig.

## Use Anywhere!
Because the library is written in Zig it can easily be used by Zig, C, and C++.
Since zig-html-canvas is self standing and doesn't rely on external libraries it
can be compiled to run anywhere that LLVM supports including freestanding web assembly.

### Installation
Copy `html-canvas.zig` and its dependency `vexlib.zig` into your project and then in 
your main zig file use `@import("html-canvas.zig")`.

### Rendering Output
zig-html-canvas only computes the graphics, but it does not render them. To render the
graphics import a third party library such as SDL via `sudo apt install libsdl2-dev`.
Then copy the `sdllib.c` and `sdllib.h` files into your project and follow the example
in `main.zig` to create an app window and render the canvas' drawing buffer to the window.

## API
The official JS wrapper has the exact same API as a real html canvas context. The Zig version of the library due to being a staticly typed language has a few differences for example instead of `ctx.fillStyle = "#ffffff"` you must use `ctx.fillStyle = [_]u8{255, 255, 255, 255}` instead.
