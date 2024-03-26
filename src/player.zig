const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const util = @import("util.zig");
const constants = @import("constants.zig");

pub const Player = struct {
    const Self = @This();

    basketTexture: rl.Texture2D,
    position: rl.Vector2,
    velocity: f32,

    pub fn init() Self {
        const basketTexture = rl.loadTexture(constants.TEXTURE_DIR ++ "KB2.png");
        errdefer rl.unloadTexture(basketTexture);

        const pos = rl.Vector2.init(500, 900);

        return Self{
            .basketTexture = basketTexture,
            .position = pos,
            .velocity = 0.0,
        };
    }

    pub fn unload(self: *Self) void {
        rl.unloadTexture(self.basketTexture);
    }
};
