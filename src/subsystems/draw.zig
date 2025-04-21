const matrix = @import("matrix.zig");

pub const ColorEnum = enum { RED, GREEN, BLUE, YELLOW, PURPLE, WHITE, OFF };

/// Returns a renderable color struct for functions
/// like matrix.setPixel() and matrix.clearFrame()
pub fn Color(color: ColorEnum) matrix.Led {
    const returnColor: matrix.Led = switch (color) {
        ColorEnum.RED => matrix.Led{ .r = 1, .g = 0, .b = 0 },
    };

    return returnColor;
}
