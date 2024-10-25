const vexlib = @import("vexlib");
const As = vexlib.As;
const Math = vexlib.Math;

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const cairo = @cImport({
    @cInclude("cairo/cairo.h");
});

pub const CairoItems = struct {
    sdlSurface: *sdl.SDL_Surface,
    ctx: *cairo.cairo_t,
    surface: *cairo.cairo_surface_t,

    pub fn alloc(logicalWidth: u32, logicalHeight: u32, renderWidth: u32, rendererHeight: u32) ?CairoItems {
        // create SDL surface
        const sdlSurfaceONULL = sdl.SDL_CreateRGBSurface(
            0, // flags (empty)
            @as(c_int, @intCast(renderWidth)), @as(c_int, @intCast(rendererHeight)), // surface dimensions
            32, // bit depth
            0x00ff0000, 0x0000ff00, 0x000000ff, 0 // rgba masks
        );
        if (sdlSurfaceONULL == null) {
            return null;
        }
        const sdlSurface: *sdl.SDL_Surface = @ptrCast(sdlSurfaceONULL);

        const cairo_x_multiplier = As.f32(renderWidth) / As.f32(logicalWidth);
        const cairo_y_multiplier = As.f32(rendererHeight) / As.f32(logicalHeight);

        // create cairo surface
        const crSurface = cairo.cairo_image_surface_create_for_data(
            @as([*c]u8, @ptrCast(sdlSurface.pixels)),
            cairo.CAIRO_FORMAT_RGB24,
            sdlSurface.w,
            sdlSurface.h,
            sdlSurface.pitch
        );
        if (crSurface == null) {
            return null;
        }

        cairo.cairo_surface_set_device_scale(crSurface, cairo_x_multiplier, cairo_y_multiplier);
        
        // create cairo rendering context
        const cr: ?*cairo.cairo_t = cairo.cairo_create(crSurface);
        if (cr == null) {
            return null;
        }

        return CairoItems{
            .sdlSurface = sdlSurface,
            .ctx = cr.?,
            .surface = crSurface.?
        };
    }

    pub fn dealloc(self: *CairoItems) void {
        cairo.cairo_destroy(self.ctx);
        cairo.cairo_surface_destroy(self.surface);
    }
};

pub fn renderClearRect(
    x: i32, y: i32, w: i32, h: i32,
    crItems: CairoItems
) void {
    cairo.cairo_set_source_rgba(crItems.ctx, 0.0, 0.0, 0.0, 0.0);
    cairo.cairo_rectangle(crItems.ctx, x, y, w, h);
    cairo.cairo_fill(crItems.ctx);
}

pub fn renderLine(
    x1: i32, y1: i32, x2: i32, y2: i32, lineWidth: u32, lineCap: u8,
    crItems: CairoItems, clr: [4]u8, antialiasing: bool
) void {
    _=antialiasing;
    const cairoLineCap = switch (lineCap) {
        'b' => cairo.CAIRO_LINE_CAP_BUTT,
        'r' => cairo.CAIRO_LINE_CAP_ROUND,
        's' => cairo.CAIRO_LINE_CAP_SQUARE,
        else => cairo.CAIRO_LINE_CAP_ROUND
    };
    cairo.cairo_move_to(crItems.ctx, As.f64(x1), As.f64(y1));
    cairo.cairo_line_to(crItems.ctx, As.f64(x2), As.f64(y2));
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_set_line_cap(crItems.ctx, @as(c_uint, @intCast(cairoLineCap)));
    cairo.cairo_set_line_width(crItems.ctx, As.f64(lineWidth));
    cairo.cairo_stroke(crItems.ctx);    
}

pub fn renderRectangle(
    x: i32, y: i32, w: i32, h: i32,
    crItems: CairoItems, clr: [4]u8
) void {
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_rectangle(crItems.ctx, As.f64(x), As.f64(y), As.f64(w), As.f64(h));
    cairo.cairo_fill(crItems.ctx);
}

pub fn renderTriangle(
    x1: i32, y1: i32, x2: i32, y2: i32, x3: i32, y3: i32, 
    crItems: CairoItems, clr: [4]u8
) void {
    cairo.cairo_move_to(crItems.ctx, As.f64(x1), As.f64(y1));
    cairo.cairo_line_to(crItems.ctx, As.f64(x2), As.f64(y2));
    cairo.cairo_line_to(crItems.ctx, As.f64(x3), As.f64(y3));
    cairo.cairo_line_to(crItems.ctx, As.f64(x1), As.f64(y1));
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_fill(crItems.ctx);
}

pub fn renderStrokeRectangle(
    x: i32, y: i32, w: i32, h: i32, lineWidth: u32,
    crItems: CairoItems, clr: [4]u8, antialiasing: bool
) void {
    _=antialiasing;
    cairo.cairo_move_to(crItems.ctx, As.f64(x), As.f64(y));
    cairo.cairo_line_to(crItems.ctx, As.f64(x + w), As.f64(y));
    cairo.cairo_line_to(crItems.ctx, As.f64(x + w), As.f64(y + h));
    cairo.cairo_line_to(crItems.ctx, As.f64(x), As.f64(y + h));
    cairo.cairo_line_to(crItems.ctx, As.f64(x), As.f64(y));
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_set_line_cap(crItems.ctx, cairo.CAIRO_LINE_CAP_ROUND);
    cairo.cairo_set_line_width(crItems.ctx, As.f64(lineWidth));
    cairo.cairo_stroke(crItems.ctx);
}

pub fn renderEllipse(
    x: i32, y: i32, w: i32, h: i32,
    crItems: CairoItems, clr: [4]u8
) void {
    _=h;
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_arc(crItems.ctx, As.f64(x), As.f64(y), As.f64(w), 0.0, 2 * Math.PI);
    cairo.cairo_fill(crItems.ctx);
}

pub fn renderStrokeEllipse(
    x: i32, y: i32, w: i32, h: i32, lineWidth: u32,
    crItems: CairoItems, clr: [4]u8, antialiasing: bool
) void {
    _=h;
    _=antialiasing;
    cairo.cairo_set_line_width(crItems.ctx, As.f64(lineWidth));
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_arc(crItems.ctx, As.f64(x), As.f64(y), As.f64(w), 0.0, 2 * Math.PI);
    cairo.cairo_stroke(crItems.ctx);
}

        // const xc: f32 = 320.0;
        // const yc: f32 = 240.0;
        // const radius: f32 = 200.0;
        // const angle1: f32 = 45.0  * As.f32(Math.PI / 180.0);
        // const angle2: f32 = 180.0 * As.f32(Math.PI / 180.0);

        // cairo.cairo_set_source_rgba(cr, 0, 0, 0, 1.0);
        // cairo.cairo_set_line_width(cr, 10.0);
        // cairo.cairo_arc(cr, xc, yc, radius, angle1, angle2);
        // cairo.cairo_stroke(cr);

        // cairo.cairo_set_source_rgba(cr, 1, 0.2, 0.2, 0.6);
        // cairo.cairo_set_line_width(cr, 6.0);

        // cairo.cairo_arc(cr, xc, yc, 10.0, 0, 2*Math.PI);
        // cairo.cairo_fill(cr);

        // cairo.cairo_arc(cr, xc, yc, radius, angle1, angle1);
        // cairo.cairo_line_to(cr, xc, yc);
        // cairo.cairo_arc(cr, xc, yc, radius, angle2, angle2);
        // cairo.cairo_line_to(cr, xc, yc);
        // cairo.cairo_stroke(cr);

        // cairo.cairo_select_font_face (cr, "Sans", cairo.CAIRO_FONT_SLANT_NORMAL,
        //                         cairo.CAIRO_FONT_WEIGHT_BOLD);
        // cairo.cairo_set_font_size (cr, 90.0);

        // cairo.cairo_move_to (cr, 10.0, 135.0);
        // cairo.cairo_show_text (cr, "Hello");

        // cairo.cairo_move_to (cr, 70.0, 165.0);
        // cairo.cairo_text_path (cr, "void");
        // cairo.cairo_set_source_rgb (cr, 0.5, 0.5, 1);
        // cairo.cairo_fill_preserve (cr);
        // cairo.cairo_set_source_rgb (cr, 0, 0, 0);
        // cairo.cairo_set_line_width (cr, 2.56);
        // cairo.cairo_stroke (cr);
