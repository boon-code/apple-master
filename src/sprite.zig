const std = @import("std");
const rl = @import("raylib");
const f32FromInt = @import("util.zig").f32FromInt;
// Sprites

pub const SpriteSheetUniform = struct {
    const Self = @This();
    const Index = SpriteIndex2D(Self);

    texture: rl.Texture2D,
    numSprites: i32, // rows
    numFrames: i32, // cols
    rec: rl.Rectangle,

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
        };
    }

    pub fn initFromFile(path: [:0]const u8, numSprites: i32, numFrames: i32) Self {
        const texture = rl.loadTexture(path);
        return Self.init(texture, numSprites, numFrames);
    }

    pub fn createIndex(self: Self, spriteIndex: i32, frameIndex: i32) Index {
        return Index.init(self, spriteIndex, frameIndex);
    }

    pub fn draw(self: Self, position: rl.Vector2, index: Index, mode: DrawMode) void {
        var rec = self.rec;
        rec.y = index.spriteIndexF32() * self.rec.height;
        rec.x = index.frameIndexF32() * self.rec.width;
        switch (mode) {
            .normal => {},
            .flip_vertical => rec.width *= -1.0,
        }
        rl.drawTextureRec(self.texture, rec, position, rl.Color.white); // Draw part of the texture
    }

    pub fn unload(self: *Self) void {
        rl.unloadTexture(self.texture);
    }
};

pub fn SpriteIndex2D(comptime T: type) type {
    return struct {
        const Self = @This();
        const Animated = AnimatedIndexType(Self);

        spriteIndex: i32,
        frameIndex: i32,
        spriteSheet: T,

        pub fn init(spriteSheet: T, spriteIndex: i32, frameIndex: i32) Self {
            return Self{ .spriteIndex = spriteIndex, .frameIndex = frameIndex, .spriteSheet = spriteSheet };
        }

        pub fn advanceFrame(self: *Self, byNum: i32) void {
            self.frameIndex = @mod((self.frameIndex + byNum), self.spriteSheet.numFrames);
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

        pub fn createAnimated(self: Self, duration: f64) Animated {
            return Animated.init(self, duration);
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

        pub fn init(index: IndexType, duration: f64) Self {
            return Self{ .index = index, .duration = duration, .nextUpdate = rl.getTime() };
        }

        pub fn update(self: *Self, t: f64) void {
            if (t >= self.nextUpdate) {
                const advanceNum = @divFloor((t - self.nextUpdate), self.duration) + 1;
                self.index.advanceFrame(@intFromFloat(advanceNum));
                self.nextUpdate = t + self.duration;
            }
        }
    };
}

pub const Sprite = struct {
    const Self = @This();

    sheet: SpriteSheetUniform,
    index: SpriteSheetUniform.Index,

    fn initPriv(sheet: SpriteSheetUniform, spriteIndex: i32) Self {
        const index = sheet.createIndex(spriteIndex, 0);
        return Self{ .sheet = sheet, .index = index };
    }

    pub fn init(texture: rl.Texture2D, numFrames: i32) !Self {
        return Self.initPriv(SpriteSheetUniform.init(texture, 1, numFrames), 1);
    }

    pub fn initFromFile(path: [:0]const u8, numFrames: i32) !Self {
        return Self.initPriv(SpriteSheetUniform.initFromFile(path, 1, numFrames), 1);
    }

    pub fn fromSpriteSheet(spriteSheet: SpriteSheetUniform, spriteIndex: i32) Self {
        return Self.initPriv(spriteSheet, spriteIndex);
    }

    pub fn next(self: *Self) void {
        self.advance(1);
    }

    pub fn advance(self: *Self, byNum: i32) void {
        self.index.advanceFrame(byNum);
    }

    pub fn draw(self: Self, position: rl.Vector2) void {
        self.sheet.draw(position, self.index, .normal);
    }

    pub fn drawFlipped(self: Self, position: rl.Vector2) void {
        self.sheet.draw(position, self.index, .flip_vertical);
    }
};

pub const AutoPlaySprite = struct {
    const Self = @This();

    sprite: Sprite,
    duration: f64,
    nextUpdate: f64,

    pub fn init(sprite: Sprite, duration: f64) Self {
        const nextUpdate: f64 = rl.getTime();
        return Self{ .sprite = sprite, .duration = duration, .nextUpdate = nextUpdate };
    }

    pub fn update(self: *Self, t: f64) void {
        if (t >= self.nextUpdate) {
            const advanceNum = @divFloor((t - self.nextUpdate), self.duration) + 1;
            self.sprite.advance(@intFromFloat(advanceNum));
            self.nextUpdate = t + self.duration;
        }
    }

    pub inline fn draw(self: Self, position: rl.Vector2) void {
        self.sprite.draw(position);
    }

    pub inline fn drawFlipped(self: Self, position: rl.Vector2) void {
        self.sprite.drawFlipped(position);
    }
};
