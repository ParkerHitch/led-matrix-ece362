const math = @import("std").math;

pub const Vec3 = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,

    pub fn init(x: i32, y: i32, z: i32) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn add(self: *Vec3, v2: *Vec3) Vec3 {
        return Vec3{ .x = self.x + v2.x, .y = self.y + v2.y, .z = self.z + v2.z };
    }

    pub fn sub(self: *Vec3, v2: *Vec3) Vec3 {
        return Vec3{ .x = self.x - v2.x, .y = self.y - v2.y, .z = self.z - v2.z };
    }

    pub fn mult(self: *Vec3, c: i32) Vec3 {
        return Vec3{ .x = self.x * c, .y = self.y * c, .z = self.z * c };
    }

    pub fn div(self: *Vec3, c: i32) Vec3 {
        return Vec3{ .x = self.x / c, .y = self.y / c, .z = self.z / c };
    }

    pub fn dot(self: *Vec3, v2: *Vec3) i32 {
        return self.x * v2.x + self.y * v2.y + self.z * v2.z;
    }

    pub fn cross(self: *Vec3, v2: *Vec3) Vec3 {
        return Vec3{ .x = self.y * v2.z - self.z * v2.y, .y = self.z * v2.x - self.x * v2.z, .z = self.x * v2.y - self.y * v2.x };
    }

    pub fn mag(self: *Vec3) i32 {
        return math.sqrt(math.pow(self.x, 2) + math.pow(self.y, 2) + math.pow(self.z, 2));
    }

    pub fn distSquared(self: *Vec3, v2: *Vec3) i32 {
        return math.pow(self.x - v2.x, 2) + math.pow(self.y - v2.y, 2) + math.pw(self.z - v2.z, 2);
    }
};

pub const Vec3f = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn init(x: f32, y: f32, z: f32) Vec3f {
        return Vec3f{ .x = x, .y = y, .z = z };
    }

    pub fn add(self: *Vec3f, v2: *Vec3f) Vec3f {
        return Vec3f{ .x = self.x + v2.x, .y = self.y + v2.y, .z = self.z + v2.z };
    }

    pub fn sub(self: *Vec3f, v2: *Vec3f) Vec3f {
        return Vec3f{ .x = self.x - v2.x, .y = self.y - v2.y, .z = self.z - v2.z };
    }

    pub fn mult(self: *Vec3f, c: f32) Vec3f {
        return Vec3f{ .x = self.x * c, .y = self.y * c, .z = self.z * c };
    }

    pub fn div(self: *Vec3f, c: f32) Vec3f {
        return Vec3f{ .x = self.x / c, .y = self.y / c, .z = self.z / c };
    }

    pub fn dot(self: *Vec3f, v2: *Vec3f) f32 {
        return self.x * v2.x + self.y * v2.y + self.z * v2.z;
    }

    pub fn cross(self: *Vec3f, v2: *Vec3f) Vec3f {
        return Vec3f{ .x = self.y * v2.z - self.z * v2.y, .y = self.z * v2.x - self.x * v2.z, .z = self.x * v2.y - self.y * v2.x };
    }

    pub fn mag(self: *Vec3f) f32 {
        return math.sqrt(math.pow(self.x, 2) + math.pow(self.y, 2) + math.pow(self.z, 2));
    }

    pub fn distSquared(self: *Vec3f, v2: *Vec3f) f32 {
        return math.pow(self.x - v2.x, 2) + math.pow(self.y - v2.y, 2) + math.pw(self.z - v2.z, 2);
    }
};
