const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const util = @import("util.zig");
const apple = @import("apple.zig");
const constants = @import("constants.zig");
const player = @import("player.zig");
const plus = @import("plus.zig");

const f32FromInt = util.f32FromInt;

pub const State = struct {
    // Types
    const Self = @This();
    const SpriteSheetUniform = sprite.SpriteSheetUniform;
    const SpriteIndex = sprite.SpriteSheetUniform.Index;
    const AnimationIndex = sprite.SpriteSheetUniform.Index.Animated;

    // Sprites
    background: rl.Texture2D,

    apple_manager: apple.AppleManager,

    health_back: rl.Texture2D,
    health_front: rl.Texture2D,

    player: player.Player,
    plus_effect: plus.BonusEffect,

    delta: f32,
    time: f64,
    base_time: f64,
    paused: bool,
    show_key_map: bool,

    health: f32,
    hurt: f32,
    score: u64,

    debug: bool,

    // Implementation

    pub fn init(allocator: std.mem.Allocator) !Self {
        const time: f64 = 0.0;
        const base_time = rl.getTime();
        const background = sprite.loadTextureEmbed(constants.TEXTURE_DIR ++ "BG.png");
        errdefer rl.unloadTexture(background);

        var man = try apple.AppleManager.init(allocator, time);
        errdefer man.unload();

        // Health bar
        const health_back = sprite.loadTextureEmbed(constants.TEXTURE_DIR ++ "STR1.png");
        errdefer rl.unloadTexture(health_back);
        const health_front = sprite.loadTextureEmbed(constants.TEXTURE_DIR ++ "STR2.png");
        errdefer rl.unloadTexture(health_front);
        std.debug.assert(health_back.width == health_front.width);
        std.debug.assert(health_back.height == health_front.height);

        var p = player.Player.init();
        errdefer p.unload();

        var plus_effect = try plus.BonusEffect.init(allocator);
        errdefer plus_effect.unload();

        return Self{
            .background = background,
            .apple_manager = man,
            .health_back = health_back,
            .health_front = health_front,
            .player = p,
            .plus_effect = plus_effect,
            .delta = 0,
            .time = time,
            .base_time = base_time,
            .paused = false,
            .show_key_map = true,
            .health = 100.0,
            .hurt = 0.0,
            .score = 0,
            .debug = false,
        };
    }

    pub fn updateTime(self: *Self) void {
        if (self.paused) {
            self.delta = 0.0;
        } else {
            self.time = rl.getTime() - self.base_time;
            self.delta = rl.getFrameTime();
        }
    }

    pub fn updateHealth(self: *Self) void {
        self.health -= 0.01 * constants.FPS * self.delta;
        if (self.health < 0.0) {
            self.health = 0.0;
            std.debug.print("You ran out of time\n", .{});
        }
    }

    fn togglePause(self: *Self) void {
        if (self.paused) { // unpause
            self.base_time = rl.getTime() - self.time;
        }

        self.paused = !self.paused;

        self.updateTime();
    }

    pub fn updateKeys(self: *Self) void {
        if (self.health <= 0.0) {
            return;
        }

        if (rl.isKeyPressed(.key_p)) {
            self.togglePause();
        }

        if (rl.isKeyPressed(.key_k)) {
            self.show_key_map = !self.show_key_map;
        }

        if (rl.isKeyPressed(.key_d)) {
            self.debug = !self.debug;
        }

        self.player.updateKeys(self.delta);
    }

    pub fn updateMovement(self: *Self) void {
        if (self.health <= 0.0) {
            return;
        }
        _ = self.apple_manager.update(self.time);
    }

    pub fn isDebug(self: Self) bool {
        return self.debug;
    }

    pub fn caugthApple(self: *Self, apple_: *const apple.Apple) void {
        // FIXME: This is only a draft
        if (apple_.anim_index.index.sprite_index >= 4) { // BAD apple
            if (self.score > 5) {
                self.score -= 5;
            } else {
                self.score = 0;
            }
            self.health -= 5;
            self.hurt = 1.0;
            if (self.health <= 0.0) {
                self.health = 0.0;
                std.debug.print("You lost\n", .{});
            }
        } else { // good apple
            self.score += 5;
            self.health += 5;
            if (self.health > 100.0) {
                self.health = 100.0;
            }
            std.debug.print("Spawn a plus here: {d} {d}\n", .{ apple_.position.x, apple_.position.y });
            self.plus_effect.spawn(apple_.position, self.time);
        }
    }

    pub fn missedApple(self: *Self, apple_: *const apple.Apple) void {
        // FIXME: This is only a draft
        if (apple_.anim_index.index.sprite_index >= 4) { // BAD apple
            self.score += 1;
        } else {
            if (self.score > 10) {
                self.score -= 10;
            } else {
                self.score = 0;
            }
        }
    }

    pub fn draw(self: *Self) void {
        // Background
        rl.drawTexture(self.background, 0, 0, rl.Color.white);
        self.drawHealthBar();

        // Key map
        if (self.show_key_map) {
            Self.drawKeyInfo();
        }

        if (self.health <= 0.0) {
            rl.drawText("You died", 300, 200, 50, rl.Color.red);
            return;
        }

        // Apple
        self.apple_manager.drawUpdate(self.time, self.delta, self.player, self);

        // Bonus effect
        self.plus_effect.drawAndUpdate(self.time);

        // Basket
        self.player.draw(self.debug);

        // hurt effect
        self.drawHurt();

        // Paused
        if (self.paused) {
            rl.drawText("-= Game paused =-", 300, 200, 50, rl.Color.light_gray);
        }
    }

    fn drawKeyInfo() void {
        const off_x = 520;
        const off_y = 20;
        const font_size = 20;
        const space_y = 25;
        const text_color = rl.Color.light_gray.alpha(0.7);
        const key_map = [_][:0]const u8{
            "Key map:",
            "- left arrow to move left",
            "- right arrow to move right",
            "- shift to move faster",
            "- p to pause",
            "- k to toggle the key map",
            "- f to toggle full screen",
            "- q to quit",
        };
        inline for (key_map, 0..) |text, i| {
            rl.drawText(text, off_x, off_y + space_y * @as(i32, i), font_size, text_color);
        }
    }

    fn drawHurt(self: *Self) void {
        if (self.hurt > 0.0) {
            var color = rl.Color.red;
            color.a = @intFromFloat(self.hurt * self.hurt * 230);
            rl.drawRectangle(0, 0, rl.getScreenWidth(), rl.getScreenHeight(), color);
            self.hurt -= 0.01 * self.delta * constants.FPS;

            if (self.hurt < 0.0) {
                self.hurt = 0.0;
            }
        }
    }

    pub fn unload(self: *Self) void {
        rl.unloadTexture(self.background);
        rl.unloadTexture(self.health_back);
        rl.unloadTexture(self.health_front);
        self.player.unload();
        self.plus_effect.unload();
    }

    fn drawHealthBar(self: Self) void {
        const bar_y = 100.0;
        const frame_width = f32FromInt(self.health_back.width);
        const frame_height = f32FromInt(self.health_back.height);
        const origin = rl.Vector2.init(0.0, 0.0);
        const dst_width = frame_width * 2.0;
        const dst_height = frame_height * 2.0;
        // Back
        const dst_back = rl.Rectangle.init(constants.HEALTH_BAR_X, bar_y, dst_width, dst_height);
        const src_back = rl.Rectangle.init(0, 0, frame_width, frame_height);
        // Front
        const f = (100.0 - self.health) / 100.0;
        var src_dy = frame_height * f;
        var dst_dy = dst_height * f;
        const dstFront = rl.Rectangle.init(constants.HEALTH_BAR_X, bar_y + dst_dy, dst_width, dst_height - dst_dy);
        const srcFront = rl.Rectangle.init(0, src_dy, frame_width, frame_height - src_dy);

        self.drawHealtText();

        rl.drawTexturePro(self.health_back, src_back, dst_back, origin, 0.0, rl.Color.white);
        rl.drawTexturePro(self.health_front, srcFront, dstFront, origin, 0.0, rl.Color.white);
    }

    fn drawHealtText(self: Self) void {
        var buf: [100]u8 = undefined;

        const health: i32 = @intFromFloat(self.health);
        if (std.fmt.bufPrintZ(&buf, "Health: {d}", .{health})) |text| {
            rl.drawText(text, constants.HEALTH_BAR_X, 70, 20, rl.Color.light_gray);
        } else |_| {}

        if (std.fmt.bufPrintZ(&buf, "Score: {d}", .{self.score})) |text| {
            rl.drawText(text, constants.HEALTH_BAR_X, 45, 20, rl.Color.light_gray);
        } else |_| {}
    }
};
