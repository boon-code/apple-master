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
    backgroundTexture: rl.Texture2D,

    appleManager: apple.AppleManager,

    healthBack: rl.Texture2D,
    healthFront: rl.Texture2D,

    plusSpriteSheet: sprite.SpriteSheetUniform,
    plusAnimIndex: AnimationIndex,
    plusShow: bool,

    player: player.Player,
    plusEffect: plus.BonusEffect,

    delta: f32,
    time: f64,
    baseTime: f64,
    paused: bool,

    health: f32,
    hurt: f32,
    score: u64,

    debug: bool,

    // Implementation

    pub fn init(allocator: std.mem.Allocator) !Self {
        const time: f64 = 0.0;
        const baseTime = rl.getTime();
        const backgroundTexture = rl.loadTexture(constants.TEXTURE_DIR ++ "BG.png");
        errdefer rl.unloadTexture(backgroundTexture);

        var man = try apple.AppleManager.init(allocator, time);
        errdefer man.unload();

        // Health bar
        const healthBack = rl.loadTexture(constants.TEXTURE_DIR ++ "STR1.png");
        errdefer rl.unloadTexture(healthBack);
        const healthFront = rl.loadTexture(constants.TEXTURE_DIR ++ "STR2.png");
        errdefer rl.unloadTexture(healthFront);
        std.debug.assert(healthBack.width == healthFront.width);
        std.debug.assert(healthBack.height == healthFront.height);

        // ++ Animation
        var plusSpriteSheet = sprite.SpriteSheetUniform.initFromFile(constants.TEXTURE_DIR ++ "PL.png", 1, 18);
        errdefer plusSpriteSheet.unload();

        var p = player.Player.init();
        errdefer p.unload();

        var plusEffect = try plus.BonusEffect.init(allocator);
        errdefer plusEffect.unload();

        return Self{
            .backgroundTexture = backgroundTexture,
            .appleManager = man,
            .healthBack = healthBack,
            .healthFront = healthFront,
            .plusSpriteSheet = plusSpriteSheet,
            .plusAnimIndex = plusSpriteSheet.createIndex(0, 0).createAnimated(constants.PLUS_ANIM_SPEED, time),
            .plusShow = false,
            .player = p,
            .plusEffect = plusEffect,
            .delta = 0,
            .time = time,
            .baseTime = baseTime,
            .paused = false,
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
            self.time = rl.getTime() - self.baseTime;
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
            self.baseTime = rl.getTime() - self.time;
        }

        self.paused = !self.paused;

        self.updateTime();
    }

    pub fn updateKeys(self: *Self) void {
        if (self.health <= 0.0) {
            return;
        }
        if (rl.isKeyDown(.key_m)) {
            self.health -= 1.0 * self.delta * constants.FPS;
            if (self.health < 0.0) {
                self.health = 0.0;
            }
        } else if (rl.isKeyDown(.key_p)) {
            self.health += 1.0 * self.delta * constants.FPS;
            if (self.health > 100.0) {
                self.health = 100.0;
            }
        }

        if (rl.isKeyDown(.key_w)) {
            self.showPlus();
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
        _ = self.appleManager.update(self.time);

        if (self.plusShow) {
            if (self.plusAnimIndex.update(self.time)) { // wrapped
                self.plusShow = false;
            }
        }
    }

    pub fn isDebug(self: Self) bool {
        return self.debug;
    }

    pub fn caugthApple(self: *Self, apple_: *const apple.Apple) void {
        // FIXME: This is only a draft
        if (apple_.appleAnimIndex.index.spriteIndex >= 4) { // BAD apple
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
            self.plusEffect.spawn(apple_.position, self.time);
        }
    }

    pub fn missedApple(self: *Self, apple_: *const apple.Apple) void {
        // FIXME: This is only a draft
        if (apple_.appleAnimIndex.index.spriteIndex >= 4) { // BAD apple
            self.score += 1;
        } else {
            if (self.score > 10) {
                self.score -= 10;
            } else {
                self.score = 0;
            }
        }
    }

    fn showPlus(self: *Self) void {
        if (!self.plusShow) {
            self.plusAnimIndex.reset(self.time + constants.PLUS_WAIT_FIRST);
            self.plusShow = true;
        }
    }

    pub fn draw(self: *Self) void {
        // Background
        rl.drawTexture(self.backgroundTexture, 0, 0, rl.Color.white);
        self.drawHealthBar();

        if (self.health <= 0.0) {
            rl.drawText("You died", 300, 200, 50, rl.Color.red);
            return;
        }

        // Apple
        self.appleManager.drawUpdate(self.time, self.delta, self.player, self);

        // Bonus effect
        self.plusEffect.drawAndUpdate(self.time);

        // Basket
        self.player.draw(self.debug);

        // hurt effect
        self.drawHurt();

        if (self.plusShow) {
            const pos = rl.Vector2.init(400, 400);
            self.plusSpriteSheet.draw(pos, self.plusAnimIndex.index, .normal);
            var pos2 = pos;
            pos2.x += constants.PLUS_WIDTH + 2.0;
            self.plusSpriteSheet.draw(pos2, self.plusAnimIndex.index, .normal);
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
        rl.unloadTexture(self.backgroundTexture);
        rl.unloadTexture(self.healthBack);
        rl.unloadTexture(self.healthFront);
        self.appleSpriteSheet.unload();
        self.healthSpriteSheet.unload();
        self.plusSpriteSheet.unload();
        self.player.unload();
    }

    fn drawHealthBar(self: Self) void {
        const barY = 100.0;
        const frameWidth = f32FromInt(self.healthBack.width);
        const frameHeight = f32FromInt(self.healthBack.height);
        const origin = rl.Vector2.init(0.0, 0.0);
        const dstWidth = frameWidth * 2.0;
        const dstHeight = frameHeight * 2.0;
        // Back
        const dstBack = rl.Rectangle.init(constants.HEALTH_BAR_X, barY, dstWidth, dstHeight);
        const srcBack = rl.Rectangle.init(0, 0, frameWidth, frameHeight);
        // Front
        const f = (100.0 - self.health) / 100.0;
        var srcDy = frameHeight * f;
        var dstDy = dstHeight * f;
        const dstFront = rl.Rectangle.init(constants.HEALTH_BAR_X, barY + dstDy, dstWidth, dstHeight - dstDy);
        const srcFront = rl.Rectangle.init(0, srcDy, frameWidth, frameHeight - srcDy);

        self.drawHealtText();

        rl.drawTexturePro(self.healthBack, srcBack, dstBack, origin, 0.0, rl.Color.white);
        rl.drawTexturePro(self.healthFront, srcFront, dstFront, origin, 0.0, rl.Color.white);
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
