const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const util = @import("util.zig");
const constants = @import("constants.zig");

const f32FromInt = util.f32FromInt;

pub const Player = struct {
    const Self = @This();
    const X_MAX = constants.SCREEN_X_AREA - 141.0;

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

    pub fn updateKeys(self: *Self, delta: f32) void {
        const velocity = Self.getSpeed() * delta * constants.FPS;

        if (rl.isKeyDown(.key_left)) {
            self.position.x -= velocity;
        } else if (rl.isKeyDown(.key_right)) {
            self.position.x += velocity;
        }

        if (self.position.x <= 0.0) {
            self.position.x = 0.0;
        } else if (self.position.x >= X_MAX) {
            self.position.x = X_MAX;
        }

        if (rl.isKeyPressed(.key_down)) {
            self.position.y += 1.0;
        } else if (rl.isKeyPressed(.key_up)) {
            self.position.y -= 1.0;
        }
    }

    pub fn draw(self: Self) void {
        rl.drawTextureRec(self.basketTexture, self.rect, self.position, rl.Color.white);
    }

    pub fn unload(self: *Self) void {
        rl.unloadTexture(self.basketTexture);
    }

    fn isFastDown() bool {
        return rl.isKeyDown(.key_left_shift) or rl.isKeyDown(.key_right_shift);
    }

    fn getSpeed() f32 {
        if (Self.isFastDown()) {
            return 30.0;
        } else {
            return 10.0;
        }
    }
};
