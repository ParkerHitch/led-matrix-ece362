/// draw.zig
/// NOTE: these are zig only draw functions
const matrix = @import("matrix.zig");

pub const ColorEnum = enum { RED, GREEN, BLUE, YELLOW, PURPLE, TIEL, WHITE, BLACK };

/// Returns the corrisponding renderable color struct for functions
/// like matrix.setPixel() and matrix.clearFrame()
pub fn Color(color: ColorEnum) matrix.Led {
    const returnColor: matrix.Led = switch (color) {
        .RED => matrix.Led{ .r = 1, .g = 0, .b = 0 },
        .GREEN => matrix.Led{ .r = 0, .g = 1, .b = 0 },
        .BLUE => matrix.Led{ .r = 0, .g = 0, .b = 1 },
        .YELLOW => matrix.Led{ .r = 1, .g = 1, .b = 0 },
        .PURPLE => matrix.Led{ .r = 1, .g = 0, .b = 1 },
        .TIEL => matrix.Led{ .r = 0, .g = 1, .b = 1 },
        .WHITE => matrix.Led{ .r = 1, .g = 1, .b = 1 },
        .BLACK => matrix.Led{ .r = 0, .g = 0, .b = 0 },
    };

    return returnColor;
}

/// Zig only draw functions
/// NOTE: temp function implementation
pub fn box(px: i32, py: i32, pz: i32, w: i32, l: i32, h: i32, color: matrix.Led) void {
    var x: i32 = px;
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
