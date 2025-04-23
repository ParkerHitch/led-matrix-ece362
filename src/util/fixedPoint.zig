const std = @import("std");

/// Returns a struct representing a fixed point number.
/// Memory layout of the returned struct is:
///     Bits 0 (LSB. inclusive) thru decimal_len (exclusive) - the fraction component of the fixed point representation
///     Bits decimal_len (inclusive) thru decimal_len+integer_len (exclusive) - the integral component of the fp representation
///     Any necessary padding bits to get this to have a size that is a power of 2
pub fn FixedPoint(integer_size: comptime_int, fraction_size: comptime_int) type {
    const backing_size = try std.math.ceilPowerOfTwo(u16, integer_size + fraction_size);
    const padding_size = backing_size - (integer_size + fraction_size);
    const BackingInt: type = std.meta.Int(.unsigned, backing_size);
    const FractionInt: type = std.meta.Int(.unsigned, fraction_size);
    const IntegerInt: type = std.meta.Int(.unsigned, integer_size);
    const PaddingInt: type = std.meta.Int(.unsigned, padding_size);

    return packed union {
        raw: BackingInt,
        fp: packed struct(BackingInt) {
            fraction: FractionInt,
            integer: IntegerInt,
            padding: PaddingInt = 0,
        },

        const This = @This();

        // Returns a new fixed point number that is the sum of the original two
        pub fn add(a: This, b: This) This {
            return .{ .raw = a.raw + b.raw };
        }
        // Returns a new fixed point number that is the sum of the original two
        pub fn sub(a: This, b: This) This {
            return .{ .raw = a.raw - b.raw };
        }
    };
}
