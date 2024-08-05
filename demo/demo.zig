const std = @import("std");

const vexlib = @import("vexlib");
const Math = vexlib.Math;
const String = vexlib.String;
const print = vexlib.print;
const println = vexlib.println;
const Uint8Array = vexlib.Uint8Array;
const Int = vexlib.Int;

const htmlCanvas = @import("zcanvas");
const Canvas = htmlCanvas.Canvas;
const ImageData = htmlCanvas.ImageData;
const rgb = htmlCanvas.rgb;
const rgba = htmlCanvas.rgba;
const color = htmlCanvas.color;

const sdl = @cImport({
    @cInclude("./sdllib.h");
});

// SDL constants
const SDL_WINDOWPOS_CENTERED = 805240832;
const SDL_WINDOW_SHOWN = 4;
const SDL_WINDOW_BORDERLESS = 16;
const SDL_QUIT = 256;
const SDL_KEYDOWN = 768;

var sdlRunning: bool = true;

export fn handleSDLEvent(eventType: i32, eventData: i32) void {
    const KEY_ESCAPE = 27;

    switch (eventType) {
        SDL_QUIT => {
            sdlRunning = false;
        },
        SDL_KEYDOWN => {
            if (eventData == KEY_ESCAPE) {
                sdlRunning = false;
            }
        },
        else => {}
    }
}

fn rgbaToU32(r: u8, g: u8, b: u8, a: u8) u32 {
    return (@as(u32, @intCast(a)) << 24) | 
           (@as(u32, @intCast(r)) << 16) | 
           (@as(u32, @intCast(g)) <<  8) | 
           (@as(u32, @intCast(b))      );
}

pub fn main() !void {
    // setup allocator
    var generalPurposeAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = generalPurposeAllocator.deinit();
    const allocator = generalPurposeAllocator.allocator();
    vexlib.allocatorPtr = &allocator;
    
    println("Game running");
    
    // println(Float.parse("1010.0101", 10));

    // var temp = String.allocFrom(" 255");
    // defer temp.dealloc();
    // print("#");
    // print(temp.trim());
    // print("#");
    // println("---------");
    // println(Math.factorial(5));

    // create canvas
    var canvas = Canvas.alloc(allocator, 800, 600);
    defer canvas.dealloc();
    var ctx = (canvas.getContext("2d", .{}) catch unreachable).?;

    // draw
    {
        ctx.imageSmoothingEnabled = false;

        ctx.fillStyle = color("rgba(255, 255, 255, 1)");
        ctx.fillRect(0, 0, 400, 400);

        ctx.strokeStyle = color("rgba(0, 0, 0, 1)");
        ctx.lineWidth = 10;

        // Wall
        ctx.strokeRect(75, 140, 150, 110);

        // Door
        ctx.fillStyle = color("rgba(0, 0, 0, 1)");
        ctx.fillRect(130, 190, 40, 60);

        // Roof
        ctx.fillStyle = color("rgba(255, 0, 0, 1)");
        ctx.beginPath();
        ctx.moveTo(50, 140);
        ctx.lineTo(150, 60);
        ctx.lineTo(250, 140);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();

        // Window
        ctx.fillStyle = color("rgba(0, 255, 255, 1)");
        ctx.beginPath();
        ctx.arc(150, 110, 25, 0, 2.0 * @as(f32, @floatCast(Math.PI)), false);
        // ctx.stroke();
        ctx.fill();

        // Thing
        ctx.moveTo(200 + 30, 90);
        ctx.lineTo(200 + 110, 20);
        ctx.lineTo(200 + 240, 130);
        ctx.lineTo(200 + 60, 130);
        ctx.lineTo(200 + 190, 20);
        ctx.lineTo(200 + 270, 90);
        ctx.closePath();
        
    }

    sdlRunning = sdl.createWindow(
        "demo", 
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 
        800, 600, 
        SDL_WINDOW_SHOWN
    ) > 0;

    // const MASK_16 = (1 << 16) - 1;
    // const screenWidth: u32 = sdl.getScreenRes() >> 16;
    // const screenHeight: u32 = sdl.getScreenRes() & MASK_16;
    var pixels = sdl.getPixels();
    const windowWidth: u32 = sdl.getWindowRes() >> 16;
    // const windowHeight: u32 = sdl.getWindowRes() & MASK_16;

    var pix = ctx.imageData.data;
    println(pix.get((51 + 301 * windowWidth) * 4));
    println(pix.get((51 + 301 * windowWidth) * 4+1));
    println(pix.get((51 + 301 * windowWidth) * 4+2));

    while (sdlRunning) {
        sdl.pollInput();

        var i: u32 = 0;
        while (i < pix.len / 4) : (i += 1) {
            const j: u32 = @intCast(@as(u32, @truncate(i << 2)));

            const r = pix.get(j);
            const g = pix.get(j+1);
            const b = pix.get(j+2);
            const a = pix.get(j+3);

            pixels[@intCast(@as(usize, i))] = rgbaToU32(r, g, b, a);
        }

        sdl.updateWindow();
        sdl.wait(16);
    }

    sdl.destroyWindow();
}