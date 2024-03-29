const std = @import("std");
const rl = @import("raylib");
const util = @import("util.zig");
const f32FromInt = util.f32FromInt;
// Sprites

pub const SpriteSheetUniform = struct {
    pub const Index = SpriteIndex2D(Self);
    const Self = @This();

    texture: rl.Texture2D,
    num_sprites: i32, // rows
    num_frames: i32, // cols
    rec: rl.Rectangle,

    frame_height: f32,
    frame_width: f32,

    pub fn init(texture: rl.Texture2D, num_sprites: i32, num_frames: i32) Self {
        std.debug.assert(num_frames > 0);
        std.debug.assert(num_sprites > 0);
        const frame_height: f32 = @floatFromInt(@divFloor(texture.height, num_sprites));
        const frame_width: f32 = @floatFromInt(@divFloor(texture.width, num_frames));
        return Self{
            .texture = texture,
            .num_sprites = num_sprites,
            .num_frames = num_frames,
            .rec = rl.Rectangle.init(0.0, 0.0, frame_width, frame_height),
            .frame_width = frame_width,
            .frame_height = frame_height,
        };
    }

    pub fn initFromFile(path: [:0]const u8, num_sprites: i32, num_frames: i32) Self {
        const texture = rl.loadTexture(path);
        return Self.init(texture, num_sprites, num_frames);
    }

    pub fn createIndex(self: Self, sprite_index: i32, frame_index: i32) Index {
        return Index.init(self, sprite_index, frame_index);
    }

    pub fn initFromEmbeddedFile(comptime path: [:0]const u8, num_sprites: i32, num_frames: i32) Self {
        const texture = loadTextureEmbed(path);
        return Self.init(texture, num_sprites, num_frames);
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

        sprite_index: i32,
        frame_index: i32,
        sprite_sheet: T,

        pub fn init(sprite_sheet: T, sprite_index: i32, frame_index: i32) Self {
            return Self{ .sprite_index = sprite_index, .frame_index = frame_index, .sprite_sheet = sprite_sheet };
        }

        pub fn advanceFrame(self: *Self, byNum: i32) bool {
            const newIndex = @mod((self.frame_index + byNum), self.sprite_sheet.num_frames);
            const wrapped = (newIndex < self.frame_index);
            self.frame_index = newIndex;
            return wrapped;
        }

        pub fn setFrameWrap(self: *Self, index: i32) void {
            self.frame_index = @mod(index, self.sprite_sheet.num_frames);
        }

        pub fn setSprite(self: *Self, index: i32) void {
            std.debug.assert(index < self.sprite_sheet.num_sprites);
            self.sprite_index = index;
            self.frame_index = 0;
        }

        pub fn nextSprite(self: *Self) void {
            const sprite_index = @mod((self.sprite_index + 1), self.sprite_sheet.num_sprites);
            self.setSprite(sprite_index);
        }

        pub fn previousSprite(self: *Self) void {
            const sprite_index = @mod((self.sprite_index - 1 + self.sprite_sheet.num_sprites), self.sprite_sheet.num_sprites);
            self.setSprite(sprite_index);
        }

        pub inline fn spriteIndexF32(self: Self) f32 {
            return @floatFromInt(self.sprite_index);
        }

        pub inline fn frameIndexF32(self: Self) f32 {
            return @floatFromInt(self.frame_index);
        }

        pub fn createAnimated(self: Self, duration: f64, next_update: f64) Animated {
            return Animated.init(self, duration, next_update);
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
        next_update: f64,

        pub fn init(index: IndexType, duration: f64, next_update: f64) Self {
            return Self{ .index = index, .duration = duration, .next_update = next_update };
        }

        pub fn reset(self: *Self, t: f64) void {
            self.index.setFrameWrap(0);
            self.next_update = t + self.duration;
        }

        pub fn update(self: *Self, t: f64) bool {
            if (t >= self.next_update) {
                const advance_num = @divFloor((t - self.next_update), self.duration) + 1;
                const wrapped = self.index.advanceFrame(@intFromFloat(advance_num));
                self.next_update = t + self.duration;
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
