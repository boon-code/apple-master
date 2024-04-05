const std = @import("std");
const rl = @import("raylib");
const util = @import("util.zig");
const f32FromInt = util.f32FromInt;
// Sprites

pub const SimpleSprite = struct {
    const Self = @This();

    src_rec: rl.Rectangle,
    texture: rl.Texture2D,
    width: i32,
    height: i32,

    pub fn init(path: [:0]const u8, width: i32, height: i32) Self {
        const texture = rl.loadTexture(path);
        return Self{
            .texture = texture,
            .src_rec = Self.initRect(texture, width, height),
            .width = width,
            .height = height,
        };
    }

    pub fn initEmbed(comptime path: [:0]const u8, width: i32, height: i32) Self {
        const texture = loadTextureEmbed(path);
        return Self{
            .texture = texture,
            .src_rec = Self.initRect(texture, width, height),
            .width = width,
            .height = height,
        };
    }

    inline fn initRect(texture: rl.Texture2D, width: i32, height: i32) rl.Rectangle {
        const height_max: i32 = @intCast(texture.height);
        const width_max: i32 = @intCast(texture.width);
        std.debug.print("{} {} {} {}\n", .{ height_max, height, width_max, width });
        std.debug.assert(height_max >= height);
        std.debug.assert(width_max >= width);
        std.debug.assert(width > 0);
        std.debug.assert(height > 0);

        const width_f32: f32 = @floatFromInt(width);
        const height_f32: f32 = @floatFromInt(height);

        return rl.Rectangle.init(0, 0, width_f32, height_f32);
    }

    pub inline fn drawTextureRec(self: Self, rec: rl.Rectangle, position: rl.Vector2, tint: rl.Color) void {
        rl.drawTextureRec(self.texture, rec, position, tint);
    }

    pub inline fn drawTexturePro(self: Self, src: rl.Rectangle, dst: rl.Rectangle, position: rl.Vector2, rotation: f32, tint: rl.Color) void {
        rl.drawTexturePro(self.texture, src, dst, position, rotation, tint);
    }

    pub inline fn drawTexture(self: Self, x: f32, y: f32, tint: rl.Color) void {
        const position = rl.Vector2.init(x, y);
        rl.drawTextureRec(self.texture, self.src_rec, position, tint);
    }

    pub inline fn unload(self: *Self) void {
        rl.unloadTexture(self.texture);
    }
};

pub const SpriteSheetUniform = struct {
    pub const Index = SpriteIndex2D(Self);
    const Self = @This();

    sprite: SimpleSprite,
    num_sprites: i32, // rows
    num_frames: i32, // cols
    rec: rl.Rectangle,

    pub fn init(sprite: SimpleSprite, num_sprites: i32, num_frames: i32) Self {
        std.debug.assert(num_frames > 0);
        std.debug.assert(num_sprites > 0);
        const frame_height: f32 = @floatFromInt(@divFloor(sprite.height, num_sprites));
        const frame_width: f32 = @floatFromInt(@divFloor(sprite.width, num_frames));
        return Self{
            .sprite = sprite,
            .num_sprites = num_sprites,
            .num_frames = num_frames,
            .rec = rl.Rectangle.init(0.0, 0.0, frame_width, frame_height),
        };
    }

    pub fn initFromFile(path: [:0]const u8, num_sprites: i32, num_frames: i32, width: i32, height: i32) Self {
        const sprite = SimpleSprite.init(path, width, height);
        return Self.init(sprite, num_sprites, num_frames);
    }

    pub fn initFromEmbeddedFile(comptime path: [:0]const u8, num_sprites: i32, num_frames: i32, width: i32, height: i32) Self {
        const sprite = SimpleSprite.initEmbed(path, width, height);
        return Self.init(sprite, num_sprites, num_frames);
    }

    pub fn createIndex(self: Self, sprite_index: i32, frame_index: i32) Index {
        return Index.init(self, sprite_index, frame_index);
    }

    pub fn draw(self: Self, position: rl.Vector2, index: Index, mode: DrawMode) void {
        const rec = self.getSourceRect(index, mode);
        self.sprite.drawTextureRec(rec, position, rl.Color.white); // Draw part of the texture
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
        self.sprite.unload();
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
