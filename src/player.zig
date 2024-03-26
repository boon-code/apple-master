const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const util = @import("util.zig");
const constants = @import("constants.zig");

const f32FromInt = util.f32FromInt;

pub const Player = struct {
    const Self = @This();

    basketTexture: rl.Texture2D,
    rect: rl.Rectangle,
    position: rl.Vector2,
    velocity: f32,

    pub fn init() Self {
        const basketTexture = rl.loadTexture(constants.TEXTURE_DIR ++ "KB2.png");
        errdefer rl.unloadTexture(basketTexture);

        const rect = rl.Rectangle.init(0, 0, f32FromInt(basketTexture.width), f32FromInt(basketTexture.height));
        const pos = rl.Vector2.init(100, constants.SCREEN_Y_APPLES_MAX - 10.0);

        return Self{
            .basketTexture = basketTexture,
            .rect = rect,
            .position = pos,
            .velocity = 0.0,
        };
    }

    pub fn draw(self: Self) void {
        rl.drawTextureRec(self.basketTexture, self.rect, self.position, rl.Color.white);
    }

    pub fn unload(self: *Self) void {
        rl.unloadTexture(self.basketTexture);
    }
};
