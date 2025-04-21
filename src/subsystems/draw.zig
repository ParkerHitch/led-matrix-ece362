const matrix = @import("matrix.zig");

pub const ColorEnum = enum { RED, GREEN, BLUE, YELLOW, PURPLE, TIEL, WHITE, BLACK };

/// Returns a renderable color struct for functions
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
