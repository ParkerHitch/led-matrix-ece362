const std = @import("std");

/// Returns a struct representing a fixed point number.
/// Memory layout of the returned struct is:
///     Bits 0 (LSB. inclusive) thru decimal_len (exclusive) - the fraction component of the fixed point representation
///     Bits decimal_len (inclusive) thru decimal_len+integer_len (exclusive) - the integral component of the fp representation
///     Any necessary padding bits to get this to have a size that is a power of 2
pub fn FixedPoint(integer_size: comptime_int, fraction_size: comptime_int, signdedness: std.builtin.Signedness) type {
    const backing_size = try std.math.ceilPowerOfTwo(u16, integer_size + fraction_size);
    const padding_size = backing_size - (integer_size + fraction_size);

    const BackingInt: type = std.meta.Int(signdedness, backing_size);
    const FractionInt: type = std.meta.Int(.unsigned, fraction_size);
    const IntegerInt: type = std.meta.Int(signdedness, integer_size);
    const PaddingInt: type = std.meta.Int(signdedness, padding_size);

    return packed union {
        raw: BackingInt,
        fp: packed struct(BackingInt) {
            fraction: FractionInt,
            integer: IntegerInt,
            padding: PaddingInt = 0,
        },

        const This = @This();

        pub const fraction_bits = fraction_size;

        /// Returns a new fixed point number (in the layout of the first opperand) that is the sum of both opperands.
        /// Supports addition with any fixed point sturct and raw integers.
        pub fn add(a: This, b: anytype) This {
            const b_type = @TypeOf(b);
            const b_type_info: std.builtin.Type = @typeInfo(b_type);

            if (b_type == This) {
                // Normal fp addition
                return .{ .raw = a.raw + b.raw };
            } else if (b_type_info == .Int or b_type == comptime_int) {
                // Addition with raw int
                return .{ .raw = a.raw + (b << fraction_size) };
            } else if (b_type_info == .Union and @hasField(b_type, "fp") and @hasDecl(b_type, "fraction_bits")) {
                // Addition with another, arbitrary fixed point number
                const shift_amt = This.fraction_bits - b_type.fraction_bits;
                if (shift_amt >= 0) {
                    return .{ .raw = a.raw + (b.raw << shift_amt) };
                } else {
                    return .{ .raw = a.raw + (b.raw >> -shift_amt) };
                }
            } else {
                @compileError("Called FixedPoint.add with unsopported second operand type. Please use a raw integer or another FixedPoint number");
            }
        }

        /// Returns a new fixed point number that is the difference of the original two
        pub fn sub(a: This, b: anytype) This {
            return a.add(b.mul(-1));
        }

        /// Returns a new fixed point number that is the product of the original two
        pub fn mul(a: This, b: anytype) This {
            const b_type = @TypeOf(b);
            const b_type_info: std.builtin.Type = @typeInfo(b_type);

            if (b_type == This) {
                // Normal fp multiplication
                return .{ .raw = ((a.raw >> (fraction_size / 2)) * (b.raw >> (fraction_size / 2))) };
            } else if (b_type_info == .Int or b_type == comptime_int) {
                // Mul with raw int
                return .{ .raw = a.raw * b };
            } else if (b_type_info == .Union and @hasField(b_type, "fp") and @hasDecl(b_type, "fraction_bits")) {
                // Mul with another, arbitrary fixed point number
                return .{ .raw = (a.raw * b.raw) >> b_type.fraction_bits };
            } else {
                @compileError("Called FixedPoint.mul with unsopported second operand type. Please use a raw integer or another FixedPoint number");
            }
        }

        pub fn div(a: This, b: anytype) This {
            const b_type = @TypeOf(b);
            const b_type_info: std.builtin.Type = @typeInfo(b_type);

            if (b_type == This) {
                const out: This = .{ .raw = @divFloor(a.raw << (fraction_size / 2), b.raw >> (fraction_size / 2)) };
                return out;
            } else if (b_type_info == .Int or b_type == comptime_int) {
                // Div with raw int
                return .{ .raw = @divFloor(a.raw, b) };
            } else if (b_type_info == .Union and @hasField(b_type, "fp") and @hasDecl(b_type, "fraction_bits")) {
                @compileError("Not implemented yet");
            } else {
                @compileError("Called FixedPoint.div with unsopported second operand type. Please use a raw integer or another FixedPoint number");
            }
        }

        pub fn fromFloatLit(f: comptime_float) This {
            comptime {
                return .{ .raw = @floor(f * (1 << fraction_size)) };
            }
        }

        pub fn sqrt(a: This) !This {
            if (a.fp.integer < 0) {
                return error.NegativeRoot;
            }
            const UnsignedBacking = std.meta.Int(.unsigned, backing_size);
            const root: BackingInt = std.math.sqrt(@as(UnsignedBacking, @intCast(a.raw)));
            return .{ .raw = root << (fraction_size / 2) };
        }

        // pub fn invSqrt(a: This) This {
        // }
        // TODO:
        // Look more into https://www.fpgarelated.com/showarticle/1347.php

        pub fn prettyPrint(self: This, writer: anytype, decimals: comptime_int) !void {
            if (backing_size > 32) {
                @compileError("No pretty print for > 32 bit fixed point");
            }
            if (self.fp.integer >= 0) {
                const tenPow: u64 = comptime std.math.pow(u64, 10, decimals);
                const bigDiv: u64 = 1 << fraction_size;
                var bigBacking: u64 = @intCast(self.fp.fraction);
                bigBacking = bigBacking * tenPow / bigDiv;
                return writer.print(
                    std.fmt.comptimePrint("{{}}.{{:0>{}}}", .{decimals}),
                    .{ self.fp.integer, bigBacking },
                );
            } else {
                try writer.print("-", .{});
                const positive = self.mul(-1);
                try positive.prettyPrint(writer, decimals);
            }
        }
    };
}

/// Struct representing a  3d mathematical vector of fixed point values.
/// scalarType is the type of each component.
/// Should be a struct returned from the FixedPoint function defined above
pub fn FpVector(scalarType: type) type {
    return struct {
        x: scalarType,
        y: scalarType,
        z: scalarType,

        const This = @This();

        /// Returns a new vector that is the result of scalar multiplication
        pub fn mulFp(a: This, b: anytype) This {
            .{
                .x = a.x.mul(b),
                .y = a.y.mul(b),
                .z = a.z.mul(b),
            };
        }

        /// Returns a new vector that is the sum of a & b
        /// Supports the same types as FixedPoint.add
        pub fn add(a: This, b: anytype) This {
            return .{
                .x = a.x.add(b.x),
                .y = a.y.add(b.y),
                .z = a.z.add(b.z),
            };
        }

        pub fn zero() This {
            return .{
                .x = .{ .raw = 0 },
                .y = .{ .raw = 0 },
                .z = .{ .raw = 0 },
            };
        }
    };
}

pub fn FpRotor(scalarType: type) type {
    return struct {
        scalar: scalarType,
        yz: scalarType,
        zx: scalarType,
        xy: scalarType,

        const This = @This();

        pub fn identity() This {
            return .{
                .scalar = scalarType.fromFloatLit(1.0),
                .xy = .{ .raw = 0 },
                .yz = .{ .raw = 0 },
                .zx = .{ .raw = 0 },
            };
        }

        pub fn mul(a: This, b: anytype) This {
            return .{
                .scalar = a.scalar.mul(b),
                .yz = a.yz.mul(b),
                .zx = a.zx.mul(b),
                .xy = a.xy.mul(b),
            };
        }

        pub fn add(a: This, b: This) This {
            return .{
                .scalar = a.scalar.add(b.scalar),
                .yz = a.yz.add(b.yz),
                .zx = a.zx.add(b.zx),
                .xy = a.xy.add(b.xy),
            };
        }

        pub fn norm(a: This) This {
            const mag = a.scalar.mul(a.scalar)
                .add(a.yz.mul(a.yz))
                .add(a.zx.mul(a.zx))
                .add(a.xy.mul(a.xy))
                .sqrt() catch unreachable;
            return .{
                .scalar = a.scalar.div(mag),
                .yz = a.yz.div(mag),
                .zx = a.zx.div(mag),
                .xy = a.xy.div(mag),
            };
        }

        pub fn prettyPrint(self: This, writer: anytype, decimals: comptime_int) !void {
            try writer.print("Rotor. real: ", .{});
            try self.scalar.prettyPrint(writer, decimals);
            try writer.print(" yz: ", .{});
            try self.yz.prettyPrint(writer, decimals);
            try writer.print(" zx: ", .{});
            try self.zx.prettyPrint(writer, decimals);
            try writer.print(" xy: ", .{});
            try self.xy.prettyPrint(writer, decimals);
            try writer.print("\n", .{});
        }
    };
}
