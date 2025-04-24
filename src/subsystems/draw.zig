/// draw.zig
/// NOTE: these are zig only draw functions
const matrix = @import("matrix.zig");
const Vec3f = @import("vec3.zig").Vec3f;

pub const ColorEnum = enum { RED, GREEN, BLUE, YELLOW, PURPLE, TEAL, WHITE, BLACK };

/// Returns the corrisponding renderable color struct for functions
/// like matrix.setPixel() and matrix.clearFrame()
pub fn Color(color: ColorEnum) matrix.Led {
    const returnColor: matrix.Led = switch (color) {
        .RED => matrix.Led{ .r = 1, .g = 0, .b = 0 },
        .GREEN => matrix.Led{ .r = 0, .g = 1, .b = 0 },
        .BLUE => matrix.Led{ .r = 0, .g = 0, .b = 1 },
        .YELLOW => matrix.Led{ .r = 1, .g = 1, .b = 0 },
        .PURPLE => matrix.Led{ .r = 1, .g = 0, .b = 1 },
        .TEAL => matrix.Led{ .r = 0, .g = 1, .b = 1 },
        .WHITE => matrix.Led{ .r = 1, .g = 1, .b = 1 },
        .BLACK => matrix.Led{ .r = 0, .g = 0, .b = 0 },
    };

    return returnColor;
}

/// drawable box struct
/// x, y, and zPos represent the matrix coordinates of the bottem left corner
/// of the box (min(x,y,z) vertex)
/// width is len(x), length is len(y), height is len(z)
pub const Box = struct {
    pos: Vec3f = .{},

    width: i32 = 0,
    length: i32 = 0,
    height: i32 = 0,

    color: matrix.Led = .{ .r = 0, .g = 0, .b = 0 },

    /// init a draw.Box with variable width, length, and height
    pub fn initBox(pos: Vec3f, width: i32, length: i32, height: i32, color: matrix.Led) Box {
        return Box{ .pos = pos, .width = width, .length = length, .height = height, .color = color };
    }

    /// init a draw.Box with uniform width, length, and height
    pub fn initCube(pos: Vec3f, size: i32, color: matrix.Led) Box {
        return Box{ .pos = pos, .width = size, .length = size, .height = size, .color = color };
    }

    pub fn draw(self: *Box) void {
        var x: i32 = @intFromFloat(@round(self.pos.x));
        while (x < self.width + @as(i32, @intFromFloat(@round(self.pos.x)))) {
            var y: i32 = @intFromFloat(@round(self.pos.y));
            while (y < self.length + @as(i32, @intFromFloat(@round(self.pos.y)))) {
                var z: i32 = @intFromFloat(@round(self.pos.z));
                while (z < self.height + @as(i32, @intFromFloat(@round(self.pos.z)))) {
                    matrix.setPixel(x, y, z, self.color);
                    z += 1;
                }
                y += 1;
            }
            x += 1;
        }
    }
};

/// Zig ONLY draw functions
/// NOTE: temp function implementation
pub fn box(px: i32, py: i32, pz: i32, w: i32, l: i32, h: i32, color: matrix.Led) void {
    var x = px;
    while (x < px + w) {
        var y = py;
        while (y < py + l) {
            var z = pz;
            while (z < pz + h) {
                matrix.setPixel(x, y, z, color);
                z += 1;
            }
            y += 1;
        }
        x += 1;
    }
}
