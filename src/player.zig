const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const util = @import("util.zig");
const constants = @import("constants.zig");

const f32FromInt = util.f32FromInt;
const SimpleSprite = sprite.SimpleSprite;

pub const Player = struct {
    const Self = @This();
    const X_MAX = (constants.apple_slot_max + 1) * constants.apple_slot_width - constants.basket_width;

    basket: SimpleSprite,
    rect: rl.Rectangle,
    position: rl.Vector2,
    velocity_factor: f32,
    direction: f32,
    snap_distance: f32,

    pub fn init() Self {
        const basket = SimpleSprite.initEmbed(constants.texture_dir ++ "KB2.png", constants.basket_width, constants.basket_height);
        errdefer basket.unload();

        const rect = rl.Rectangle.init(0, 0, basket.src_rec.width, basket.src_rec.height);
        const pos = rl.Vector2.init(100, constants.screen_y_apples_max - 10.0);

        return Self{
            .basket = basket,
            .rect = rect,
            .position = pos,
            .velocity_factor = 0.0,
            .direction = 0.0,
            .snap_distance = 0.0,
        };
    }

    pub fn updateKeys(self: *Self, delta: f32) void {
        const speedFactor = delta * constants.fps;

        self.velocity_factor += 0.1 * speedFactor;
        if (self.velocity_factor > 1.0) {
            self.velocity_factor = 1.0;
        }

        var velocity: f32 = undefined;
        if (Self.isFastDown()) {
            velocity = constants.basket_speed_fast * self.velocity_factor * speedFactor;
        } else {
            velocity = constants.basket_speed_normal * self.velocity_factor * speedFactor;
        }

        if (rl.isKeyDown(.key_left)) {
            self.direction = -1.0;
            self.calcLeftSnap();
            self.snap_distance -= velocity;
        } else if (rl.isKeyDown(.key_right)) {
            self.direction = 1.0;
            self.calcRightSnap();
            self.snap_distance -= velocity;
        } else if (rl.getTouchPointCount() >= 1) {
            velocity = constants.basket_speed_fast * self.velocity_factor * speedFactor;
            self.handleTouch(rl.getTouchPosition(0), velocity);
        } else { // neither left nor right is pressed
            if (self.snap_distance <= 0.0) {
                self.direction = 0.0;
                self.velocity_factor = 0.0;
            } else {
                self.snap_distance -= velocity;
                if (self.snap_distance <= 0.0) {
                    velocity += self.snap_distance; // reduce the velocity
                    self.snap_distance = 0.0;
                }
            }
        }

        if (self.snap_distance < 0.0) {
            self.snap_distance = 0.0;
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

    fn handleTouch(self: *Self, touch_pos: rl.Vector2, velocity: f32) void {
        const x = touch_pos.x;
        if (x < (self.position.x + constants.basket_width * 0.5)) {
            self.direction = -1.0;
            self.calcLeftSnap();
            self.snap_distance -= velocity;
        } else {
            self.direction = 1.0;
            self.calcRightSnap();
            self.snap_distance -= velocity;
        }
    }

    fn calcLeftSnap(self: *Self) void {
        const last = Self.getLastSnap(self.position.x);
        self.snap_distance = self.position.x - last;
    }

    fn calcRightSnap(self: *Self) void {
        const next = Self.getNextSnap(self.position.x);
        self.snap_distance = next - self.position.x;
    }

    fn getLastSnapIndex(x: f32) i32 {
        return @divFloor(@as(i32, @intFromFloat(x)), constants.apple_slot_width);
    }

    fn getLastSnap(x: f32) f32 {
        const snapX = Self.getLastSnapIndex(x) * constants.apple_slot_width;
        return @floatFromInt(snapX);
    }

    fn getNextSnap(x: f32) f32 {
        const next = Self.getLastSnapIndex(x + constants.basket_width) + 1;
        if (next > constants.apple_slot_max) {
            return X_MAX;
        }
        var newX: f32 = @floatFromInt(next);
        newX = newX * constants.apple_slot_width - constants.basket_width;

        if (newX > x) {
            return newX;
        } else {
            return x;
        }
    }

    pub fn draw(self: Self, debug: bool) void {
        self.basket.drawTextureRec(self.rect, self.position, rl.Color.white);
        if (debug) {
            self.drawDebugText();
            self.drawBoundingBox();
        }
    }

    fn drawBoundingBox(self: Self) void {
        const appleHeight = constants.apple_height - 14; // FIXME: find actual pixel value
        const x1: i32 = @intFromFloat(self.position.x);
        const y1: i32 = @intFromFloat(self.position.y - appleHeight);
        const w1: i32 = @intFromFloat(self.rect.width);
        const h1: i32 = @intFromFloat(constants.apple_height + 7); // FIXME: check how many pixels this is
        var color1 = rl.Color.yellow;
        color1.a = 50;
        rl.drawRectangle(x1, y1, w1, h1, color1);

        const x2: i32 = @intFromFloat(self.position.x + constants.apple_offset_x);
        const y2: i32 = @intFromFloat(self.position.y - appleHeight);
        const w2: i32 = @intFromFloat(self.rect.width - constants.apple_offset_x * 2);
        const h2: i32 = @intFromFloat(appleHeight);
        var color2 = rl.Color.red;
        color2.a = 128;
        rl.drawRectangle(x2, y2, w2, h2, color2);
    }

    pub fn catchesApple(self: Self, position: rl.Vector2, inc: f32) bool {
        const appleHeight = constants.apple_height - 14; // FIXME: find actual pixel value
        const top = (position.y >= (self.position.y - (appleHeight + 7))); // FIXME: actual pixel offset
        const bottom = (position.y <= (self.position.y - appleHeight + inc)); // inc: Account for motion
        const left = (position.x >= (self.position.x - constants.apple_offset_x));
        const right = (position.x <= (self.position.x + constants.basket_width - constants.apple_width + constants.apple_offset_x));
        const isCaught = top and bottom and left and right;
        if (isCaught) {
            std.debug.print("catchesApple: apple: {d}, {d}; basket: {d}, {d}\n", .{ position.x, position.y, self.position.x, self.position.y });
        }
        return isCaught;
    }

    fn drawDebugText(self: Self) void {
        var buf: [100]u8 = undefined;

        if (std.fmt.bufPrintZ(&buf, "Position: {d}", .{self.position.x})) |text| {
            rl.drawText(text, constants.health_bar_x, 375, 20, rl.Color.light_gray);
        } else |_| {}

        if (std.fmt.bufPrintZ(&buf, "Snap: {d}", .{self.snap_distance})) |text| {
            rl.drawText(text, constants.health_bar_x, 400, 20, rl.Color.light_gray);
        } else |_| {}
    }

    pub fn unload(self: *Self) void {
        self.basket.unload();
    }

    fn isFastDown() bool {
        return rl.isKeyDown(.key_left_shift) or rl.isKeyDown(.key_right_shift);
    }
};
