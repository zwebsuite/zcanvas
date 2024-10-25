const std = @import("std");

const zcanvas = @import("zcanvas");
const Canvas = zcanvas.Canvas;
const color = zcanvas.color;

const Window = zcanvas.Window;
const Key = Window.Key;
const WindowEvent = Window.Event;

const vexlib = @import("vexlib");
const Math = vexlib.Math;
const As = vexlib.As;
const print = vexlib.print;
const println = vexlib.println;

var running = true;

pub fn eventHandler(event: WindowEvent) void {
    switch (event.which) {
        .Quit => {
            running = false;
        },
        .KeyDown => {
            if (event.data == Key.Escape) {
                running = false;
            }
        },
        .Unknown => {

        }
    }
}

pub fn main() !void {
    // setup allocator
    var generalPurposeAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = generalPurposeAllocator.allocator();
    vexlib.init(&allocator);

    // init SDL
    try Window.initSDL(Window.INIT_EVERYTHING);

    const logicalWidth = 400;
    const logicalHeight = 400;
    const renderScale = 4;

    // create a window
    var myWin = try Window.SDLWindow.alloc(.{
        .title = "Demo Window",
        .width = logicalWidth * renderScale,
        .height = logicalHeight * renderScale,
        .flags = Window.WINDOW_SHOWN
    });
    myWin.eventHandler = eventHandler; // attach event handler

    // create canvas & rendering context
    var canvas = Canvas.alloc(allocator, logicalWidth, logicalHeight, renderScale, zcanvas.RendererType.Cairo);
    defer canvas.dealloc();
    var ctx = try canvas.getContext("2d", .{});

    // attach canvas to window
    myWin.setCanvas(&canvas);

    // print dimensions
    print("logical width: ");
    println(canvas.width);
    print("logical height: ");
    println(canvas.height);
    print("render width: ");
    println(myWin.width);
    print("render height: ");
    println(myWin.height);

    // draw stuff
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
    ctx.stroke();
    ctx.fill();

    // Thing
    ctx.moveTo(200 + 30, 90);
    ctx.lineTo(200 + 110, 20);
    ctx.lineTo(200 + 240, 130);
    ctx.lineTo(200 + 60, 130);
    ctx.lineTo(200 + 190, 20);
    ctx.lineTo(200 + 270, 90);
    ctx.closePath();

    while (running) {
        // check for events
        myWin.pollInput();

        // render frame
        try myWin.render();

        // wait for 16ms
        Window.wait(16);
    }

    // clean up
    myWin.dealloc();
}
