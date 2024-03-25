// Everything related to the apples
const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const constants = @import("constants.zig");

const AnimatedIndex = sprite.SpriteSheetUniform.Index.Animated;

const Apple = struct {
    active: bool,
    position: rl.Vector2,
    appleAnimIndex: AnimatedIndex,
};

const AppleManager = struct {
    const Self = @This();

    appleSpriteSheet: sprite.SpriteSheetUniform,
    apples: []Apple,
    allocator: std.mem.Allocator,

    pub fn init() !Self {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = try gpa.allocator();
        const apples = allocator.alloc(Apple, 500);
        const appleSpriteSheet = sprite.SpriteSheetUniform.initFromFile(constants.textureDir ++ "AE2.png", 8, 8);

        return Self{
            .appleSpriteSheet = appleSpriteSheet,
            .apples = apples,
            .allocator = allocator,
        };
    }

    pub fn unload() void {}
};
