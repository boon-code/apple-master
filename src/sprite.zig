const std = @import("std");
const rl = @import("raylib");
const util = @import("util.zig");
const f32FromInt = util.f32FromInt;
// Sprites

pub const SpriteSheetUniform = struct {
    pub const Index = SpriteIndex2D(Self);
    const Self = @This();

    texture: rl.Texture2D,
    numSprites: i32, // rows
    numFrames: i32, // cols
    rec: rl.Rectangle,

    frameHeight: f32,
    frameWidth: f32,

    pub fn init(texture: rl.Texture2D, numSprites: i32, numFrames: i32) Self {
        std.debug.assert(numFrames > 0);
        std.debug.assert(numSprites > 0);
        const frameHeight: f32 = @floatFromInt(@divFloor(texture.height, numSprites));
        const frameWidth: f32 = @floatFromInt(@divFloor(texture.width, numFrames));
        return Self{
            .texture = texture,
            .numSprites = numSprites,
            .numFrames = numFrames,
            .rec = rl.Rectangle.init(0.0, 0.0, frameWidth, frameHeight),
            .frameWidth = frameWidth,
            .frameHeight = frameHeight,
        };
    }

    pub fn initFromFile(path: [:0]const u8, numSprites: i32, numFrames: i32) Self {
        const texture = rl.loadTexture(path);
        return Self.init(texture, numSprites, numFrames);
    }

    pub fn createIndex(self: Self, spriteIndex: i32, frameIndex: i32) Index {
        return Index.init(self, spriteIndex, frameIndex);
    }

    pub fn initFromEmbeddedFile(comptime path: [:0]const u8, numSprites: i32, numFrames: i32) Self {
        const texture = loadTextureEmbed(path);
        return Self.init(texture, numSprites, numFrames);
    }

    pub fn draw(self: Self, position: rl.Vector2, index: Index, mode: DrawMode) void {
        const rec = self.getSourceRect(index, mode);
        rl.drawTextureRec(self.texture, rec, position, rl.Color.white); // Draw part of the texture
    }

    pub inline fn getSourceRect(self: Self, index: Index, mode: DrawMode) rl.Rectangle {
        var rec = self.rec;
        rec.y = index.spriteIndexF32() * self.rec.height;
        rec.x = index.frameIndexF32() * self.rec.width;
        switch (mode) {
            .normal => {},
            .flip_vertical => rec.width *= -1.0,
        }
        return rec;
    }

    pub fn unload(self: *Self) void {
        rl.unloadTexture(self.texture);
    }
};

pub fn SpriteIndex2D(comptime T: type) type {
    return struct {
        pub const Animated = AnimatedIndexType(Self);
        const Self = @This();

        spriteIndex: i32,
        frameIndex: i32,
        spriteSheet: T,

        pub fn init(spriteSheet: T, spriteIndex: i32, frameIndex: i32) Self {
            return Self{ .spriteIndex = spriteIndex, .frameIndex = frameIndex, .spriteSheet = spriteSheet };
        }

        pub fn advanceFrame(self: *Self, byNum: i32) bool {
            const newIndex = @mod((self.frameIndex + byNum), self.spriteSheet.numFrames);
            const wrapped = (newIndex < self.frameIndex);
            self.frameIndex = newIndex;
            return wrapped;
        }

        pub fn setFrameWrap(self: *Self, index: i32) void {
            self.frameIndex = @mod(index, self.spriteSheet.numFrames);
        }

        pub fn setSprite(self: *Self, index: i32) void {
            std.debug.assert(index < self.spriteSheet.numSprites);
            self.spriteIndex = index;
            self.frameIndex = 0;
        }

        pub fn nextSprite(self: *Self) void {
            const spriteIndex = @mod((self.spriteIndex + 1), self.spriteSheet.numSprites);
            self.setSprite(spriteIndex);
        }

        pub fn previousSprite(self: *Self) void {
            const spriteIndex = @mod((self.spriteIndex - 1 + self.spriteSheet.numSprites), self.spriteSheet.numSprites);
            self.setSprite(spriteIndex);
        }

        pub inline fn spriteIndexF32(self: Self) f32 {
            return @floatFromInt(self.spriteIndex);
        }

        pub inline fn frameIndexF32(self: Self) f32 {
            return @floatFromInt(self.frameIndex);
        }

        pub fn createAnimated(self: Self, duration: f64, nextUpdate: f64) Animated {
            return Animated.init(self, duration, nextUpdate);
        }
    };
}

pub const DrawMode = enum {
    normal,
    flip_vertical,
};

pub fn AnimatedIndexType(comptime IndexType: type) type {
    return struct {
        const Self = @This();

        index: IndexType,
        duration: f64,
        nextUpdate: f64,

        pub fn init(index: IndexType, duration: f64, nextUpdate: f64) Self {
            return Self{ .index = index, .duration = duration, .nextUpdate = nextUpdate };
        }

        pub fn reset(self: *Self, t: f64) void {
            self.index.setFrameWrap(0);
            self.nextUpdate = t + self.duration;
        }

        pub fn update(self: *Self, t: f64) bool {
            if (t >= self.nextUpdate) {
                const advanceNum = @divFloor((t - self.nextUpdate), self.duration) + 1;
                const wrapped = self.index.advanceFrame(@intFromFloat(advanceNum));
                self.nextUpdate = t + self.duration;
                return wrapped;
            } else {
                return false;
            }
        }
    };
}

pub fn loadTextureEmbed(comptime path: [:0]const u8) rl.Texture2D {
    const mem = @embedFile(path);
    const ext = comptime util.getExtension(path);
    if (ext) |file_fype| {
        const img = rl.loadImageFromMemory(file_fype, mem);
        return rl.loadTextureFromImage(img);
    } else {
        @compileError("Couldn't determine file type from file extension: " ++ path);
    }
}
