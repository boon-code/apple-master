const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const util = @import("util.zig");
const constants = @import("constants.zig");

const f32FromInt = util.f32FromInt;

pub const Player = struct {
    const Self = @This();
    const X_MAX = (constants.APPLE_SLOT_MAX + 1) * constants.APPLE_SLOT_WIDTH - constants.BASKET_WIDTH;

    basketTexture: rl.Texture2D,
    rect: rl.Rectangle,
    position: rl.Vector2,
    velocityFactor: f32,
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
            .velocityFactor = 0.0,
            .direction = 0.0,
            .snapDistance = 0.0,
        };
    }

    pub fn updateKeys(self: *Self, delta: f32) void {
        const speedFactor = delta * constants.FPS;

        self.velocityFactor += 0.1 * speedFactor;
        if (self.velocityFactor > 1.0) {
            self.velocityFactor = 1.0;
        }

        var velocity: f32 = undefined;
        if (Self.isFastDown()) {
            velocity = constants.BASKET_SPEED_FAST * self.velocityFactor * speedFactor;
        } else {
            velocity = constants.BASKET_SPEED_NORMAL * self.velocityFactor * speedFactor;
        }

        if (rl.isKeyDown(.key_left)) {
            self.direction = -1.0;
            self.calcLeftSnap();
            self.snapDistance -= velocity;
        } else if (rl.isKeyDown(.key_right)) {
            self.direction = 1.0;
            self.calcRightSnap();
            self.snapDistance -= velocity;
        } else { // neither left nor right is pressed
            if (self.snapDistance <= 0.0) {
                self.direction = 0.0;
                self.velocityFactor = 0.0;
            } else {
                self.snapDistance -= velocity;
                if (self.snapDistance <= 0.0) {
                    velocity += self.snapDistance; // reduce the velocity
                    self.snapDistance = 0.0;
                }
            }
        }

        self.position.x += velocity * self.direction;

        if (self.position.x < 0.0) {
            self.position.x = 0.0;
        } else if (self.position.x > X_MAX) {
            self.position.x = X_MAX;
        }

        if (rl.isKeyDown(.key_down)) {
            self.position.y += 1.0 * speedFactor;
        } else if (rl.isKeyDown(.key_up)) {
            self.position.y -= 1.0 * speedFactor;
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
            return X_MAX;
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
        self.drawDebugText();
        rl.drawTextureRec(self.basketTexture, self.rect, self.position, rl.Color.white);
    }

    fn drawDebugText(self: Self) void {
        var buf: [100]u8 = undefined;

        if (std.fmt.bufPrintZ(&buf, "Position: {d}", .{self.position.x})) |text| {
            rl.drawText(text, constants.HEALTH_BAR_X, 20, 20, rl.Color.light_gray);
        } else |_| {}

        if (std.fmt.bufPrintZ(&buf, "Snap: {d}", .{self.snapDistance})) |text| {
            rl.drawText(text, constants.HEALTH_BAR_X, 400, 20, rl.Color.light_gray);
        } else |_| {}
    }

    pub fn unload(self: *Self) void {
        rl.unloadTexture(self.basketTexture);
    }

    fn isFastDown() bool {
        return rl.isKeyDown(.key_left_shift) or rl.isKeyDown(.key_right_shift);
    }
};
