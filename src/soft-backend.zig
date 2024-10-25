const vexlib = @import("vexlib");
const As = vexlib.As;
const Math = vexlib.Math;
const Array = vexlib.Array;

const zcanvas = @import("./zcanvas.zig");
const ImageData = zcanvas.ImageData;

pub const SoftwareItems = struct {
    imgData: ImageData = undefined,
    scale: f32 = undefined
};

fn getLineLineIntersect(x1: i32, y1: i32, x2: i32, y2: i32, x3: i32, y3: i32, x4: i32, y4: i32) ?[2]i32 {
    // Check if none of the lines are of length 0
    if ((x1 == x2 and y1 == y2) or (x3 == x4 and y3 == y4)) {
        return null;
    }
    
    const a = y4 - y3;
    const b = x2 - x1;
    const c = x4 - x3;
    const d = y2 - y1;
    const e = y1 - y3;
    const f = x1 - x3;
    const denominator = (a * b - c * d);
    
    // Lines are parallel
    if (denominator == 0.0) {
        return null;
    }
    
    const denom = As.f32(denominator);
    const ua = As.f32(c * e - a * f) / denom;
    const ub = As.f32(b * e - d * f) / denom;
    
    // is the intersection along the segments
    if (ua < 0.0 or ua > 1.0 or ub < 0.0 or ub > 1.0) {
        return null;
    }
    
    // Return a object with the x and y coordinates of the intersection
    return [_]i32{
        x1 + As.i32(ua * As.f32(b)),
        y1 + As.i32(ua * As.f32(d))
    };
}

fn point_triangleColl(px: i32, py: i32, tx1: i32, ty1: i32, tx2: i32, ty2: i32, tx3: i32, ty3: i32) bool {
    // Credit: Larry Serflaton
    const tx1_3 = tx1 - tx3;
    const tx3_2 = tx3 - tx2;
    const ty2_3 = ty2 - ty3;
    const ty3_1 = ty3 - ty1;
    const px_x3 = px - tx3;
    const py_y3 = py - ty3;
    const denom = As.f32(ty2_3 * tx1_3 + tx3_2 * (ty1 - ty3));
    const a = As.f32(ty2_3 * px_x3 + tx3_2 * py_y3) / denom;
    const b = As.f32(ty3_1 * px_x3 + tx1_3 * py_y3) / denom;
    const c = 1 - a - b;
    return a > 0 and b > 0 and c > 0 and c < 1 and b < 1 and a < 1;
}


fn blendClrs(
    r1_: u8, g1_: u8, b1_: u8, a1_: u8,
    r2_: u8, g2_: u8, b2_: u8, a2_: u8
) [4]u8{
    const r1 = As.f32(r1_);
    const g1 = As.f32(g1_);
    const b1 = As.f32(b1_);
    const a1 = As.f32(a1_);
    const r2 = As.f32(r2_);
    const g2 = As.f32(g2_);
    const b2 = As.f32(b2_);
    const a2 = As.f32(a2_);

    _=r1;
    _=g1;
    _=b1;
    _=a1;
    // _=r2;
    // _=g2;
    // _=b2;
    // _=a2;
    
    return [_]u8{
        @intFromFloat(r2),
        @intFromFloat(g2),
        @intFromFloat(b2),
        @intFromFloat(a2 / 2.0)
        // @intFromFloat((r1 + r2) / 2.0),
        // @intFromFloat((g1 + g2) / 2.0),
        // @intFromFloat((b1 + b2) / 2.0),
        // @intFromFloat((a1 + a2) / 2.0),
    };
    // return [_]u8{
    //     @as(u8, @intFromFloat((r1 * (255 - a2) + r2 * a2) / 255.0)),
    //     @as(u8, @intFromFloat((g1 * (255 - a2) + g2 * a2) / 255.0)),
    //     @as(u8, @intFromFloat((b1 * (255 - a2) + b2 * a2) / 255.0)),
    //     255 - @as(u8, @intFromFloat(((255 - a1) * (255 - a1) / 255)))
    // };
}

inline fn getBufferIdx(x: i32, y: i32, width: i32) u32 {
    return As.u32(x + y * width) << 2;
}

inline fn renderPixel(
    dataBuffer: []u8, idx: u32,
    r: u8, g: u8, b: u8, a: u8
) void {
    var buff = dataBuffer;
    if (a == 255) {
        buff[idx] = r;
        buff[idx+1] = g;
        buff[idx+2] = b;
        // buff[idx+3] = a;
    } else {
        const nA = As.u32(a);
        const oR = As.u32(buff[idx]) * (255 - nA);
        const oG = As.u32(buff[idx+1]) * (255 - nA);
        const oB = As.u32(buff[idx+2]) * (255 - nA);
        
        const nR = As.u32(r) * nA;
        const nG = As.u32(g) * nA;
        const nB = As.u32(b) * nA;

        buff[idx] = As.u8T((oR + nR));
        buff[idx+1] = As.u8T((oG + nG));
        buff[idx+2] = As.u8T((oB + nB));
        // buff[idx+3] = buff[idx+3] + a;
    }
}

pub fn renderClearRect(
    x_: i32, y_: i32, width: i32, height: i32,
    swItems: SoftwareItems
) void {
    const sclx = As.i32(As.f32(x_) * swItems.scale);
    const scly = As.i32(As.f32(y_) * swItems.scale);
    const sclwidth = As.i32(As.f32(width) * swItems.scale);
    const sclheight = As.i32(As.f32(height) * swItems.scale);

    var x: u32 = sclx;
    while (x < sclx + sclwidth) : (x += 1) {
        var y: u32 = scly;
        while (y < scly + sclheight) : (y += 1) {
            const idx = (x + y * swItems.imgData.width) << 2;
            swItems.imgData.data.set(idx, 0);
            swItems.imgData.data.set(idx+1, 0);
            swItems.imgData.data.set(idx+2, 0);
            swItems.imgData.data.set(idx+3, 0);
        }
    }
}

pub fn renderLine(
    x1_: i32, y1_: i32, x2_: i32, y2_: i32, lineWidth: u32, lineCap: u8,
    swItems: SoftwareItems, clr: [4]u8, antialiasing: bool
) void {
    const sclx1 = As.i32(As.f32(x1_) * swItems.scale);
    const scly1 = As.i32(As.f32(y1_) * swItems.scale);
    const sclx2 = As.i32(As.f32(x2_) * swItems.scale);
    const scly2 = As.i32(As.f32(y2_) * swItems.scale);
    const passItems = SoftwareItems {
        .imgData = swItems.imgData,
        .scale = 1
    };

    var pix = swItems.imgData.data;
    const WIDTH = As.i32(swItems.imgData.width);

    const clrR: u8 = clr[0];
    const clrG: u8 = clr[1];
    const clrB: u8 = clr[2];
    const clrA: u8 = clr[3];

    if (lineWidth == 1) {
        if (antialiasing) {
            const fpart = struct {
                fn fpart(x: f32) f32 {
                    return x - Math.floor(x);
                }
            }.fpart;

            const rfpart = struct {
                fn rfpart(x: f32) f32 {
                    return 1 - fpart(x);
                }
            }.rfpart;

            var x1 = As.f32(sclx1);
            var y1 = As.f32(scly1);
            var x2 = As.f32(sclx2);
            var y2 = As.f32(scly2);
            
            // plot(x1, y1, 255, 0);
            // plot(x2, y2, 255, 0);

            const steep = Math.abs(y2 - y1) > Math.abs(x2 - x1);
            
            if (steep) {
                var temp = x1;
                x1 = y1;
                y1 = temp;
                temp = x2;
                x2 = y2;
                y2 = temp;
            }
            if (x1 > x2) {
                var temp = x1;
                x1 = x2;
                x2 = temp;
                temp = y1;
                y1 = y2;
                y2 = temp;
            }
            
            const dx = x2 - x1;
            const dy = y2 - y1;    
            const gradient: f32 = if (dx == 0.0) 1.0 else dy / dx;

            // handle first endpoint
            var xend = x1;
            var yend = y1 + gradient * (xend - x1);
            var xgap = rfpart(x1 + 0.5);
            const xpxl1 = xend; // this will be used in the main loop

            // first y-intersection for the main loop
            var intery = yend + gradient;

            // handle second endpoint
            xend = x2;
            yend = y2 + gradient * (xend - x2);
            xgap = fpart(x2 + 0.5);
            const xpxl2 = xend; // this will be used in the main loop

            if (steep) {
                var x = xpxl1;
                while (x <= xpxl2) : (x += 1) {
                    var idx = getBufferIdx(As.i32(Math.floor(intery)), As.i32(x), WIDTH);
                    if (idx >= 0 and idx < pix.len - 3) {
                        const c = blendClrs(
                            pix.get(idx), pix.get(idx+1), pix.get(idx+2), pix.get(idx+3),
                            clrR, clrG, clrB, As.u8(As.f32(clrA) * rfpart(intery)),
                        );
                        renderPixel(
                            pix.buffer, idx,
                            c[0], c[1], c[2], c[3]
                        );
                    }
                    

                    idx = getBufferIdx(As.i32(Math.floor(intery)) - 1, As.i32(x), WIDTH);
                    if (idx >= 0 and idx < pix.len - 3) {
                        const c = blendClrs(
                            pix.get(idx), pix.get(idx+1), pix.get(idx+2), pix.get(idx+3),
                            clrR, clrG, clrB, As.u8(As.f32(clrA) * fpart(intery)),
                        );
                        renderPixel(
                            pix.buffer, idx,
                            c[0], c[1], c[2], c[3]
                        );
                    }

                    intery = intery + gradient;
                }
            } else {
                var x = xpxl1;
                while (x <= xpxl2) : (x += 1) {
                    var idx = getBufferIdx(As.i32(x), As.i32(Math.floor(intery)), WIDTH);
                    if (idx >= 0 and idx < pix.len - 3) {
                        const c = blendClrs(
                            pix.get(idx), pix.get(idx+1), pix.get(idx+2), pix.get(idx+3),
                            clrR, clrG, clrB, As.u8(As.f32(clrA) * rfpart(intery)),
                        );
                        renderPixel(
                            pix.buffer, idx,
                            c[0], c[1], c[2], c[3]
                        );
                    }

                    idx = getBufferIdx(As.i32(x), As.i32(Math.floor(intery)) - 1, WIDTH);
                    if (idx >= 0 and idx < pix.len - 3) {
                        const c = blendClrs(
                            pix.get(idx), pix.get(idx+1), pix.get(idx+2), pix.get(idx+3),
                            clrR, clrG, clrB, As.u8(As.f32(clrA) * fpart(intery)),
                        );
                        renderPixel(
                            pix.buffer, idx,
                            c[0], c[1], c[2], c[3]
                        );
                    }

                    intery = intery + gradient;
                }
            }
        } else {
            // KCF's Bresenham Line Algorithm
            const dx = Math.abs(sclx2 - sclx1);
            const dy = Math.abs(scly2 - scly1);
            const sx: i32 = if (sclx1 < sclx2) 1 else -1;
            const sy: i32 = if (scly1 < scly2) 1 else -1;

            if (dy == 0) {
                var x = sclx1;
                while (x != sclx2 + sx) : (x += sx) {
                    const idx = As.u32((x + scly1 * WIDTH) << 2);
                    renderPixel(
                        pix.buffer, idx,
                        clrR, clrG, clrB, clrA
                    );
                }
            } else if (dx == 0) {
                var y = scly1;
                while (y != scly2 + sy) : (y += sy) {
                    const idx = As.u32((sclx1 + y * WIDTH) << 2);
                    renderPixel(
                        pix.buffer, idx,
                        clrR, clrG, clrB, clrA
                    );
                }
            } else {
                var err = dx - dy;

                var xx = sclx1;
                var yy = scly1;
                
                while (true) {
                    if (xx >= 0 and xx < WIDTH) {
                        const idx = As.u32((xx + yy * WIDTH) << 2);
                        renderPixel(
                            pix.buffer, idx,
                            clrR, clrG, clrB, clrA
                        );
                    }

                    if (xx == sclx2 and yy == scly2) {
                        break;
                    }

                    const e2 = 2 * err;
                    if (e2 > -dy) {
                        err -= dy;
                        xx += sx;
                    }
                    if (e2 < dx) {
                        err += dx;
                        yy += sy;
                    }
                }
            }
        }
    } else {
        const dx = As.f32(sclx2 - sclx1);
        const dy = As.f32(scly2 - scly1);
        // const len = @as(i32, @bitCast(Math.sqrt(@as(u32, @bitCast(dx * dx + dy * dy)))));
        const halfSW = As.i32(lineWidth / 2);
        const angle = Math.atan2(dy, dx);
        
        // check if lineCap is butt or round
        if (lineCap == 'b' or lineCap == 'r') {
            const f32_halfSw = As.f32(halfSW) * swItems.scale;
            const off1 = angle + Math.PI / 2.0;
            const off2 = angle - Math.PI / 2.0;
            const quadX1 = sclx1 + As.i32(f32_halfSw * Math.cos(off1));
            const quadY1 = scly1 + As.i32(f32_halfSw * Math.sin(off1));
            const quadX2 = sclx1 + As.i32(f32_halfSw * Math.cos(off2));
            const quadY2 = scly1 + As.i32(f32_halfSw * Math.sin(off2));
            const quadX3 = sclx2 + As.i32(f32_halfSw * Math.cos(off2));
            const quadY3 = scly2 + As.i32(f32_halfSw * Math.sin(off2));
            const quadX4 = sclx2 + As.i32(f32_halfSw * Math.cos(off1));
            const quadY4 = scly2 + As.i32(f32_halfSw * Math.sin(off1));

            renderTriangle(
                quadX1, quadY1,
                quadX2, quadY2,
                quadX3, quadY3,
                passItems, clr
            );
            renderTriangle(
                quadX1, quadY1,
                quadX3, quadY3,
                quadX4, quadY4,
                passItems, clr
            );

            if (lineCap == 'r') { // round
                renderEllipse(sclx1, scly1, halfSW-1, halfSW-1, passItems, clr);
                renderEllipse(sclx2, scly2, halfSW-1, halfSW-1, passItems, clr);
            }
        } else if (lineCap == 's') { // lineCap is square
            // let dir = Math.atan2(y2 - y1, x2 - x1),
            //     xShift = cos(dir) * halfSW,
            //     yShift = sin(dir) * halfSW;
            
            // renderPolygon(
            //     [
            //         x1 + xo - xShift, y1 - yo - yShift,
            //         x2 + xo + xShift, y2 - yo + yShift,
            //         x2 - xo + xShift, y2 + yo + yShift,
            //         x1 - xo - xShift, y1 + yo - yShift
            //     ],
            //     imgData,
            //     clr
            // );
        }
    }

    
}


pub fn renderTriangle(
    x1_: i32, y1_: i32, x2_: i32, y2_: i32, x3_: i32, y3_: i32, 
    swItems: SoftwareItems, clr: [4]u8
) void {
    const sclx1 = As.i32(As.f32(x1_) * swItems.scale);
    const scly1 = As.i32(As.f32(y1_) * swItems.scale);
    const sclx2 = As.i32(As.f32(x2_) * swItems.scale);
    const scly2 = As.i32(As.f32(y2_) * swItems.scale);
    const sclx3 = As.i32(As.f32(x3_) * swItems.scale);
    const scly3 = As.i32(As.f32(y3_) * swItems.scale);

    const pix = swItems.imgData.data;
    const WIDTH = As.i32(swItems.imgData.width);
    const HEIGHT = As.i32(swItems.imgData.height);

    const clrR: u8 = clr[0];
    const clrG: u8 = clr[1];
    const clrB: u8 = clr[2];
    const clrA: u8 = clr[3];

    const minx = @max(0, @min(sclx1, sclx2, sclx3));
    const maxx = @min(WIDTH, @max(sclx1, sclx2, sclx3));
    const miny = @max(0, @min(scly1, scly2, scly3));
    const maxy = @min(HEIGHT, @max(scly1, scly2, scly3));

    var xx = minx;
    while (xx < maxx) : (xx += 1) {
        var yy = miny;
        while (yy < maxy) : (yy += 1) {
            const w1 = As.f32(sclx1 * (scly3 - scly1) + (yy - scly1) * (sclx3 - sclx1) - xx * (scly3 - scly1)) / As.f32((scly2 - scly1) * (sclx3 - sclx1) - (sclx2 - sclx1) * (scly3 - scly1));
            const w2 = As.f32(sclx1 * (scly2 - scly1) + (yy - scly1) * (sclx2 - sclx1) - xx * (scly2 - scly1)) / As.f32((scly3 - scly1) * (sclx2 - sclx1) - (sclx3 - sclx1) * (scly2 - scly1));

            if (w1 >= 0 and w2 >= 0 and w1 + w2 <= 1) {
                const idx = As.u32(xx + yy * WIDTH) << 2;
                renderPixel(
                    pix.buffer, idx,
                    clrR, clrG, clrB, clrA
                );
            }
        }
    }
}

pub fn renderStrokeTriangle(
    x1_: i32, y1_: i32, x2_: i32, y2_: i32, x3_: i32, y3_: i32, lineWidth: u32,
    swItems: SoftwareItems, clr: [4]u8, antialiasing: bool
) void {
    const sclx1 = As.i32(As.f32(x1_) * swItems.scale);
    const scly1 = As.i32(As.f32(y1_) * swItems.scale);
    const sclx2 = As.i32(As.f32(x2_) * swItems.scale);
    const scly2 = As.i32(As.f32(y2_) * swItems.scale);
    const sclx3 = As.i32(As.f32(x3_) * swItems.scale);
    const scly3 = As.i32(As.f32(y3_) * swItems.scale);
    const passItems = SoftwareItems {
        .imgData = swItems.imgData,
        .scale = 1
    };

    renderLine(
        sclx1, scly1, sclx2, scly2, lineWidth, 'b',
        passItems, clr, antialiasing
    );

    renderLine(
        sclx2, scly2, sclx3, scly3, lineWidth, 'b',
        passItems, clr, antialiasing
    );

    renderLine(
        sclx3, scly3, sclx1, scly1, lineWidth, 'b',
        passItems, clr, antialiasing
    );
}


pub fn renderRectangle(
    x_: i32, y_: i32, w_: i32, h_: i32,
    swItems: SoftwareItems, clr: [4]u8
) void {
    const sclx = As.i32(As.f32(x_) * swItems.scale);
    const scly = As.i32(As.f32(y_) * swItems.scale);
    const sclw = As.i32(As.f32(w_) * swItems.scale);
    const sclh = As.i32(As.f32(h_) * swItems.scale);

    const pix = swItems.imgData.data;
    const WIDTH = As.i32(swItems.imgData.width);
    const HEIGHT = As.i32(swItems.imgData.height);

    const clrR: u8 = clr[0];
    const clrG: u8 = clr[1];
    const clrB: u8 = clr[2];
    const clrA: u8 = clr[3];

    const xStart: i32 = @max(sclx, 0);
    const yStart: i32 = @max(scly, 0);
    const xStop: i32 = @min(sclx + sclw, WIDTH);
    const yStop: i32 = @min(scly + sclh, HEIGHT);

    var yy: i32 = yStart;
    while (yy < yStop) : (yy += 1) {
        var xx: i32 = xStart;
        var idx = As.u32(xx + yy * WIDTH) << 2;
        while (xx < xStop) : (xx += 1) {
            renderPixel(
                pix.buffer, idx,
                clrR, clrG, clrB, clrA
            );
            idx += 4;
        }
    }
}

pub fn renderStrokeRectangle(
    x_: i32, y_: i32, w_: i32, h_: i32, lineWidth: u32,
    swItems: SoftwareItems, clr: [4]u8, antialiasing: bool
) void {


    renderLine(
        x_-10, y_, x_ + w_, y_, lineWidth, 'b',
        swItems, clr, antialiasing
    );

    renderLine(
        x_ + w_, y_, x_ + w_, y_ + h_, lineWidth, 'b',
        swItems, clr, antialiasing
    );

    renderLine(
        x_, y_ + h_, x_ + w_, y_ + h_, lineWidth, 'b',
        swItems, clr, antialiasing
    );

    renderLine(
        x_, y_, x_, y_ + h_, lineWidth, 'b',
        swItems, clr, antialiasing
    );
}

pub fn renderPolygon(
    vertices: anytype,
    swItems: SoftwareItems, clr: [4]u8
) void {
    // https://alienryderflex.com/polygon_fill/

    const pix = swItems.imgData.data;
    const WIDTH = As.i32(swItems.imgData.width);
    const clrR: u8 = clr[0];
    const clrG: u8 = clr[1];
    const clrB: u8 = clr[2];
    const clrA: u8 = clr[3];

    var y: i32 = 0; while (y < swItems.imgData.height): (y += 1) {
        var intersects = Array([2]i32).alloc(8);
        defer intersects.dealloc();

        var l: u32 = 0; while (l < vertices.len - 1) : (l += 2) {
            var idxP2 = l + 2;
            var idxP3 = l + 3;

            if (l == vertices.len - 2) {
                idxP2 = 0;
                idxP3 = 1;
            }

            if (vertices[l+1] <= y and vertices[idxP3] <= y) {
                continue;
            }

            const intersectOrNull = getLineLineIntersect(
                0, y, 400, y,
                vertices[l], vertices[l+1], vertices[idxP2], vertices[idxP3]
            );
            
            if (intersectOrNull) |intersect| {
                var j = As.i32(intersects.len) - 1;
                intersects.len += 1;
                while (j >= 0 and intersects.get(As.u32(j))[0] > intersect[0]) : (j -= 1) {
                    const u32_j = As.u32(j);
                    intersects.set(u32_j + 1, intersects.get(u32_j));
                }
                intersects.set(As.u32(j + 1), intersect);
            }
        }
        
        var i: u32 = 0; while (i < As.i32(intersects.len) - 1) : (i += 2) {
            var startX = intersects.get(i)[0];
            const endX = intersects.get(i+1)[0];
            while (startX <= endX) : (startX += 1) {
                const idx = As.u32((startX + y * WIDTH) << 2);
                renderPixel(
                    pix.buffer, idx,
                    clrR, clrG, clrB, clrA
                );
            }
        }
    }
}

// fn renderQuad(
//     x1_: i32, y1_: i32, x2_: i32, y2_: i32, x3_: i32, y3_: i32, x4_: i32, y4_: i32,
//     imageData: ImageData, clr: [4]u8
// ) void {
//     const det = @as(f32, @floatFromInt((x3_ - x1_) * (y4_ - y2_) - (x4_ - x2_) * (y3_ - y2_)));
//     var touching: bool = undefined;
//     if (det == 0) {
//         touching = false;
//     } else {
//         const lambda = @as(f32, @floatFromInt((y4_ - y2_) * (x4_ - x1_) + (x2_ - x4_) * (y4_ - y2_))) / det;
//         const gamma = @as(f32, @floatFromInt((y2_ - y3_) * (x4_ - x1_) + (x3_ - x1_) * (y4_ - y2_))) / det;
//         touching = (0.0 < lambda and lambda < 1.0) and (0.0 < gamma and gamma < 1.0);
//     }

//     var typeId: u32 = undefined;
//     var cavePt: u32 = undefined;
//     if (touching) {
//         typeId = 1;
//     } else {
//         typeId = 2;

//         if (point_triangleColl(x1_, y1_, x2_, y2_, x3_, y3_, x4_, y4_)) {
//             cavePt = 0;
//         } else if (point_triangleColl(x2_, y2_, x3_, y3_, x4_, y4_, x1_, y1_)) {
//             cavePt = 1;
//         } else if (point_triangleColl(x3_, y3_, x4_, y4_, x1_, y1_, x2_, y2_)) {
//             cavePt = 2;
//         } else if (point_triangleColl(x4_, y4_, x1_, y1_, x2_, y2_, x3_, y3_)) {
//             cavePt = 3;
//         } else {
//             typeId = 3;
//         }
//     }

//     var tri1: [6]i32 = undefined;
//     var tri2: [6]i32 = undefined;
//     switch (typeId) {
//         1 => {
//             tri1 = [_]i32{x1_, y1_, x2_, y2_, x3_, y3_};
//             tri2 = [_]i32{x1_, y1_, x3_, y3_, x4_, y4_};
//         },
//         2 => {
//             var oppositePt = cavePt + 2;
//             if (oppositePt > 3) {
//                 oppositePt %= 4;
//             }

//             var pts = Uint32Array.alloc(4);
//             defer pts.dealloc();
//             pts.append(0);
//             pts.append(1);
//             pts.append(2);
//             pts.append(3);
//             pts.remove(@as(u32, @bitCast(pts.indexOf(cavePt))), 1);
//             pts.remove(@as(u32, @bitCast(pts.indexOf(oppositePt))), 1);

//             const vals = [4][2]i32{
//                 [2]i32{x1_, y1_},
//                 [2]i32{x2_, y2_},
//                 [2]i32{x3_, y3_},
//                 [2]i32{x4_, y4_}
//             };

//             tri1 = [_]i32{vals[pts.get(0)][0], vals[pts.get(0)][1], vals[cavePt][0], vals[cavePt][1], vals[oppositePt][0], vals[oppositePt][1]};
//             tri2 = [_]i32{vals[pts.get(1)][0], vals[pts.get(1)][1], vals[cavePt][0], vals[cavePt][1], vals[oppositePt][0], vals[oppositePt][1]};
//         },
//         3 => {
//             var intersectOrNull = getLineLineIntersect(x1_, y1_, x2_, y2_, x3_, y3_, x4_, y4_);
//             if (intersectOrNull) |intersect| {
//                 tri1 = [_]i32{intersect[0], intersect[1], x2_, y2_, x3_, y3_};
//                 tri2 = [_]i32{intersect[0], intersect[1], x1_, y1_, x4_, y4_};
//             } else {
//                 intersectOrNull = getLineLineIntersect(x1_, y1_, x4_, y4_, x2_, y2_, x3_, y3_);
//                 if (intersectOrNull) |intersect| {
//                     tri1 = [_]i32{intersect[0], intersect[1], x1_, y1_, x2_, y2_};
//                     tri2 = [_]i32{intersect[0], intersect[1], x3_, y3_, x4_, y4_};
//                 } else {
//                     // I think this should be unreachable, yet somehow we're getting here
//                     tri1 = [_]i32{x1_, y1_, x2_, y2_, x3_, y3_};
//                     tri2 = [_]i32{x1_, y1_, x3_, y3_, x4_, y4_};
//                 }
//             }
//         },
//         else => unreachable
//     }

//     // println(.{tri1[0], tri1[1], tri1[2], tri1[3], tri1[4], tri1[5]});

//     renderTriangle(tri1[0], tri1[1], tri1[2], tri1[3], tri1[4], tri1[5], imageData, clr);
//     renderTriangle(tri2[0], tri2[1], tri2[2], tri2[3], tri2[4], tri2[5], imageData, clr);

//     // if (stroke && stroke[3] > 0 && strokeWeight) {
//     //     renderLine(x1, y1, x2, y2, imgData, stroke, strokeWeight, "round");
//     //     renderLine(x2, y2, x3, y3, imgData, stroke, strokeWeight, "round");
//     //     renderLine(x3, y3, x4, y4, imgData, stroke, strokeWeight, "round");
//     //     renderLine(x4, y4, x1, y1, imgData, stroke, strokeWeight, "round");
//     // }
// }


pub fn renderEllipse(
    x_: i32, y_: i32, w_: i32, h_: i32,
    swItems: SoftwareItems, clr: [4]u8
) void {
    const sclx = As.i32(As.f32(x_) * swItems.scale);
    const scly = As.i32(As.f32(y_) * swItems.scale);
    const sclw = As.i32(As.f32(w_) * swItems.scale);
    const sclh = As.i32(As.f32(h_) * swItems.scale);

    var n = sclw;
    const w2 = sclw * sclw;
    const h2 = sclh * sclh;

    const pix = swItems.imgData.data;
    const WIDTH = As.i32(swItems.imgData.width);
    // const HEIGHT = As.i32(imageData.height);

    const clrR: u8 = clr[0];
    const clrG: u8 = clr[1];
    const clrB: u8 = clr[2];
    const clrA: u8 = clr[3];

    var xStop = Math.min(sclx + sclw, WIDTH);
    {
        var i = Math.max(sclx - sclw, 0);
        while (i < xStop) : (i += 1) {
            if (i >= 0 and i < WIDTH) {
                const idx = As.u32(i + scly * WIDTH) << 2;
                renderPixel(
                    pix.buffer, idx,
                    clrR, clrG, clrB, clrA
                );
            }
        }
    }

    var j: i32 = 1;
    while (j < sclh) : (j += 1) {
        const ra = scly + j;
        const rb = scly - j;

        while (w2 * (h2 - j * j) < h2 * n * n and n != 0) {
            n -= 1;
        }

        xStop = Math.min(sclx + n, WIDTH);
        var i = Math.max(sclx - n, 0);
        while (i < xStop) : (i += 1) {
            if (i >= 0 and i < WIDTH) {
                renderPixel(
                    pix.buffer, As.u32(i + ra * WIDTH) << 2,
                    clrR, clrG, clrB, clrA
                );
    
                renderPixel(
                    pix.buffer, As.u32(i + rb * WIDTH) << 2,
                    clrR, clrG, clrB, clrA
                );
            }
        }
    }
}

pub fn renderStrokeCircle(
    x_: i32, y_: i32, d_: i32, lineWidth: u32,
    swItems: SoftwareItems, clr: [4]u8, antialiasing: bool
) void {
    _=antialiasing;
    const sclx = As.i32(As.f32(x_) * swItems.scale);
    const scly = As.i32(As.f32(y_) * swItems.scale);
    const scld = As.i32(As.f32(d_) * swItems.scale);
    const scllineWidth = As.f32(lineWidth) * swItems.scale;

    var scanLines = Array([2]i32).alloc(As.u32(Math.ceil(As.f32(scld) / 2 + scllineWidth / 2)));
    scanLines.len = scanLines.capacity();
    defer scanLines.dealloc();
    
    const dout = scld + As.i32(scllineWidth) - 1;
    const rout = As.f32(dout) / 2;
    var xx: i32 = 0;
    var yout = -Math.floor(rout);
    while (xx < -As.i32(yout)) {
        const yMid = yout + 0.5;
        const dst = As.f32(xx*xx) + yMid*yMid;
        if (dst > rout*rout) {
            yout += 1;
        }
        
        scanLines.set(As.u32(xx), [_]i32{As.i32(yout), 0});
        scanLines.set(As.u32(-yout), [_]i32{-xx, 0});
        xx += 1;
    }
    
    const din = scld - As.i32(scllineWidth);
    const rin = As.f32(din) / 2;
    xx = 0;
    var yin = -Math.floor(rin);
    while (xx < -As.i32(yin)) {
        const yMid = yin + 0.5;
        const dst = As.f32(xx*xx) + yMid*yMid;
        if (dst > rin*rin) {
            yin += 1;
        }
        
        scanLines.buffer[As.u32(xx)][1] = As.i32(yin);
        const val = scanLines.get(As.u32(-yin))[1];
        if (val != 0) {
            scanLines.buffer[As.u32(-yin)][1] = Math.max(val, -xx);
        } else {
            scanLines.buffer[As.u32(-yin)][1] = -xx;
        }
        xx += 1;
    }
    
    scanLines.buffer[As.u32(rout)][1] = 0;
    scanLines.buffer[As.u32(rin)][1] = 0;

    const pix = swItems.imgData.data;
    const WIDTH = As.i32(swItems.imgData.width);

    const clrR: u8 = clr[0];
    const clrG: u8 = clr[1];
    const clrB: u8 = clr[2];
    const clrA: u8 = clr[3];

    var i: u32 = 0; while (i < scanLines.len) : (i += 1) {
        const start = scanLines.get(i)[0];
        const stop = scanLines.get(i)[1];
        var j = start; while (j <= stop) : (j += 1) {
            renderPixel(
                pix.buffer, As.u32(sclx + As.i32(i) + (scly + j) * WIDTH) << 2,
                clrR, clrG, clrB, clrA
            );
            renderPixel(
                pix.buffer, As.u32(sclx - As.i32(i) + (scly + j) * WIDTH) << 2,
                clrR, clrG, clrB, clrA
            );
            renderPixel(
                pix.buffer, As.u32(sclx + As.i32(i) + (scly - j) * WIDTH) << 2,
                clrR, clrG, clrB, clrA
            );
            renderPixel(
                pix.buffer, As.u32(sclx - As.i32(i) + (scly - j) * WIDTH) << 2,
                clrR, clrG, clrB, clrA
            );
        }
    }
}

pub fn renderStrokeEllipse(
    x_: i32, y_: i32, w_: i32, h_: i32, lineWidth: u32,
    swItems: SoftwareItems, clr: [4]u8, antialiasing: bool
) void {
    if (w_ == h_) {
        renderStrokeCircle(x_, y_, w_ * 2, lineWidth, swItems, clr, antialiasing);
    } else {
        var i: f32 = 0.0;
        while (i < Math.PI * 2) : (i += 0.6) {
            const x1 = x_ + As.i32(Math.cos(i) * As.f32(w_));
            const y1 = y_ + As.i32(Math.sin(i) * As.f32(h_));
            const x2 = x_ + As.i32(Math.cos(i + 0.6) * As.f32(w_));
            const y2 = y_ + As.i32(Math.sin(i + 0.6) * As.f32(h_));
            renderLine(
                x1, y1, x2, y2, lineWidth, 'r',
                swItems, clr, antialiasing
            );
        }
    }
}