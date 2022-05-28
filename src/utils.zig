const c = @import("c.zig");

pub fn framebuffer(mode: *c.GXRModeObj) *anyopaque {
    return c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(mode)) orelse unreachable;
}

pub fn print(input: []const u8) void {
    _ = c.printf(@ptrCast([*c]const u8, input));
}

// Draw triangle from points and color
pub fn triangle(points: [3][2]f32, color: [3]f32) void {
    c.GX_Begin(c.GX_TRIANGLES, c.GX_VTXFMT0, 3);
    for (points) |point| {
        c.GX_Position2f32(point[0], point[1]);
        c.GX_Color3f32(color[0], color[1], color[2]);
    }
    c.GX_End();
}

// Draw square from points and color
pub fn square(points: [4][2]f32, color: [3]f32) void {
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    for (points) |point| {
        c.GX_Position2f32(point[0], point[1]);
        c.GX_Color3f32(color[0], color[1], color[2]);
    }
    c.GX_End();
}

// Draw texture from points and texture coordinates
pub fn texture(points: [4][2]f32, coords: [4][2]f32) void {
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    var i: u8 = 0;
    while (i < 4) {
        c.GX_Position2f32(points[i][0], points[i][1]);
        c.GX_TexCoord2f32(coords[i][0], coords[i][1]);
        i += 1;
    }
    c.GX_End();
}

pub fn rectangle(x: f32, y: f32, width: f32, height: f32) [4][2]f32 {
    return .{ .{ x, y }, .{ x + width, y }, .{ x + width, y + height }, .{ x, y + height } };
}
