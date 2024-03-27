const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const util = @import("util.zig");
const constants = @import("constants.zig");

const f32FromInt = util.f32FromInt;

pub const Player = struct {
    const Self = @This();
    const X_MAX = constants.SCREEN_X_AREA - 141.0;
    pub const Y_POS = constants.SCREEN_Y_APPLES_MAX - 10.0;

    basketTexture: rl.Texture2D,
    rect: rl.Rectangle,
    position: rl.Vector2,
    velocity: f32,
    direction: f32,
    snapDistance: f32,

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
            .direction = 0.0,
            .snapDistance = 0.0,
        };
    }

    pub fn updateKeys(self: *Self, delta: f32) void {
        var velocity = Self.getSpeed() * delta * constants.FPS;

        if (rl.isKeyDown(.key_left)) {
            self.direction = -1.0;
            self.calcLeftSnap();
        } else if (rl.isKeyDown(.key_right)) {
            self.direction = 1.0;
            self.calcRightSnap();
        } else { // neither left nor right is pressed
            if (self.snapDistance <= 0.0) {
                self.direction = 0.0;
            } else {
                self.snapDistance -= velocity;
                if (self.snapDistance <= 0.0) {
                    velocity += self.snapDistance; // reduce the velocity
                    self.snapDistance = 0.0;
                }
            }
        }

        self.position.x += velocity * self.direction;

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

    fn calcLeftSnap(self: *Self) void {
        const last = Self.getLastSnap(self.position.x);
        self.snapDistance = self.position.x - last;

        if (self.snapDistance < 0.0) {
            self.snapDistance = 0.0;
        }
    }

    fn calcRightSnap(self: *Self) void {
        const next = Self.getNextSnap(self.position.x);
        self.snapDistance = next - self.position.x;

        if (self.snapDistance < 0.0) {
            self.snapDistance = 0.0;
        }
    }

    fn getLastSnapIndex(x: f32) i32 {
        return @divFloor(@as(i32, @intFromFloat(x)), constants.APPLE_SLOT_WIDTH);
    }

    fn getLastSnap(x: f32) f32 {
        const snapX = Self.getLastSnapIndex(x) * constants.APPLE_SLOT_WIDTH;
        return @floatFromInt(snapX);
    }

    fn getNextSnap(x: f32) f32 {
        const next = Self.getLastSnapIndex(x + constants.BASKET_WIDTH) + 1;
        if (next > constants.APPLE_SLOT_MAX) {
            return constants.SCREEN_X_AREA - constants.BASKET_WIDTH;
        }
        var newX: f32 = @floatFromInt(next);
        newX = newX * constants.APPLE_SLOT_WIDTH - constants.BASKET_WIDTH;

        if (newX > x) {
            return newX;
        } else {
            return x;
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
