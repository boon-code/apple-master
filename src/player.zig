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

        if (self.snapDistance < 0.0) {
            self.snapDistance = 0.0;
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
    }

    fn calcRightSnap(self: *Self) void {
        const next = Self.getNextSnap(self.position.x);
        self.snapDistance = next - self.position.x;
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

    pub fn draw(self: Self, debug: bool) void {
        rl.drawTextureRec(self.basketTexture, self.rect, self.position, rl.Color.white);
        if (debug) {
            self.drawDebugText();
            self.drawBoundingBox();
        }
    }

    fn drawBoundingBox(self: Self) void {
        const appleHeight = constants.APPLE_HEIGHT - 14; // FIXME: find actual pixel value
        const x1: i32 = @intFromFloat(self.position.x);
        const y1: i32 = @intFromFloat(self.position.y - appleHeight);
        const w1: i32 = @intFromFloat(self.rect.width);
        const h1: i32 = @intFromFloat(constants.APPLE_HEIGHT + 7); // FIXME: check how many pixels this is
        var color1 = rl.Color.yellow;
        color1.a = 50;
        rl.drawRectangle(x1, y1, w1, h1, color1);

        const x2: i32 = @intFromFloat(self.position.x + constants.APPLE_OFFSET_X);
        const y2: i32 = @intFromFloat(self.position.y - appleHeight);
        const w2: i32 = @intFromFloat(self.rect.width - constants.APPLE_OFFSET_X * 2);
        const h2: i32 = @intFromFloat(appleHeight);
        var color2 = rl.Color.red;
        color2.a = 128;
        rl.drawRectangle(x2, y2, w2, h2, color2);
    }

    pub fn catchesApple(self: Self, position: rl.Vector2, inc: f32) bool {
        const appleHeight = constants.APPLE_HEIGHT - 14; // FIXME: find actual pixel value
        const top = (position.y >= (self.position.y - (appleHeight + 7))); // FIXME: actual pixel offset
        const bottom = (position.y <= (self.position.y - appleHeight + inc)); // inc: Account for motion
        const left = (position.x >= (self.position.x - constants.APPLE_OFFSET_X));
        const right = (position.x <= (self.position.x + constants.BASKET_WIDTH - constants.APPLE_WIDTH + constants.APPLE_OFFSET_X));
        const isCaught = top and bottom and left and right;
        if (isCaught) {
            std.debug.print("catchesApple: apple: {d}, {d}; basket: {d}, {d}\n", .{ position.x, position.y, self.position.x, self.position.y });
        }
        return isCaught;
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
