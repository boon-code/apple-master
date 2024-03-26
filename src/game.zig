const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const util = @import("util.zig");
const apple = @import("apple.zig");
const constants = @import("constants.zig");
const player = @import("player.zig");

const f32FromInt = util.f32FromInt;

pub const State = struct {
    // Types
    const Self = @This();
    const SpriteSheetUniform = sprite.SpriteSheetUniform;
    const SpriteIndex = sprite.SpriteSheetUniform.Index;
    const AnimationIndex = sprite.SpriteSheetUniform.Index.Animated;

    // Constants
    const APPLE_FRAME_SPEED = 0.075; // seconds
    const HEALTH_BAR_X = 870.0;

    // Sprites
    backgroundTexture: rl.Texture2D,

    appleSpriteSheet: sprite.SpriteSheetUniform,
    appleAnimIndex: AnimationIndex,
    pos: rl.Vector2,
    appleManager: apple.AppleManager,

    healthBack: rl.Texture2D,
    healthFront: rl.Texture2D,

    plusSpriteSheet: sprite.SpriteSheetUniform,
    plusAnimIndex: AnimationIndex,
    plusShow: bool,

    player: player.Player,

    delta: f32,
    time: f64,
    health: f32,
    score: u64,

    // Implementation

    pub fn init(allocator: std.mem.Allocator) !Self {
        const backgroundTexture = rl.loadTexture(constants.TEXTURE_DIR ++ "BG.png");
        errdefer rl.unloadTexture(backgroundTexture);

        // Apple sprite
        var appleSpriteSheet = sprite.SpriteSheetUniform.initFromFile(constants.TEXTURE_DIR ++ "AE2.png", 8, 8);
        errdefer appleSpriteSheet.unload();
        const appleAnimIndex = appleSpriteSheet.createIndex(0, 0).createAnimated(APPLE_FRAME_SPEED);
        const pos = rl.Vector2.init(50.0, 50.0);

        var man = try apple.AppleManager.init(allocator);
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

        const p = player.Player.init();
        errdefer p.unload();

        return Self{
            .backgroundTexture = backgroundTexture,
            .appleSpriteSheet = appleSpriteSheet,
            .appleAnimIndex = appleAnimIndex,
            .pos = pos,
            .appleManager = man,
            .healthBack = healthBack,
            .healthFront = healthFront,
            .plusSpriteSheet = plusSpriteSheet,
            .plusAnimIndex = plusSpriteSheet.createIndex(0, 0).createAnimated(constants.PLUS_ANIM_SPEED),
            .plusShow = false,
            .player = p,
            .delta = 0,
            .time = rl.getTime(),
            .health = 100.0,
            .score = 0,
        };
    }

    pub fn updateTime(self: *Self) void {
        self.time = rl.getTime();
        self.delta = rl.getFrameTime();
    }

    pub fn updateKeys(self: *Self) void {
        if (rl.isKeyPressed(.key_down)) {
            self.appleAnimIndex.index.nextSprite();
        } else if (rl.isKeyPressed(.key_up)) {
            self.appleAnimIndex.index.previousSprite();
        }

        if (rl.isKeyDown(.key_left)) {
            self.pos.x -= 5.0 * self.delta * constants.FPS;
        } else if (rl.isKeyDown(.key_right)) {
            self.pos.x += 5.0 * self.delta * constants.FPS;
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

        self.player.updateKeys(self.delta);
    }

    pub fn updateMovement(self: *Self) void {
        _ = self.appleAnimIndex.update(self.time);
        _ = self.appleManager.update(self.time);

        if (self.plusShow) {
            if (self.plusAnimIndex.update(self.time)) { // wrapped
                self.plusShow = false;
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
        var buf: [100:0]u8 = undefined;
        // Background
        rl.drawTexture(self.backgroundTexture, 0, 0, rl.Color.white);
        if (std.fmt.bufPrintZ(&buf, "Position: {d}", .{self.pos.x})) |text| {
            rl.drawText(text, 0, 100, 20, rl.Color.light_gray);
        } else |_| {}

        self.drawHealthBar();

        // Apple
        self.appleSpriteSheet.draw(self.pos, self.appleAnimIndex.index, .normal);
        self.appleManager.drawUpdate(self.time, self.delta);

        // Basket
        self.player.draw();

        if (self.plusShow) {
            const pos = rl.Vector2.init(400, 400);
            self.plusSpriteSheet.draw(pos, self.plusAnimIndex.index, .normal);
            var pos2 = pos;
            pos2.x += constants.PLUS_WIDTH + 2.0;
            self.plusSpriteSheet.draw(pos2, self.plusAnimIndex.index, .normal);
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
        const dstBack = rl.Rectangle.init(HEALTH_BAR_X, barY, dstWidth, dstHeight);
        const srcBack = rl.Rectangle.init(0, 0, frameWidth, frameHeight);
        // Front
        const f = (100.0 - self.health) / 100.0;
        var srcDy = frameHeight * f;
        var dstDy = dstHeight * f;
        const dstFront = rl.Rectangle.init(HEALTH_BAR_X, barY + dstDy, dstWidth, dstHeight - dstDy);
        const srcFront = rl.Rectangle.init(0, srcDy, frameWidth, frameHeight - srcDy);

        self.drawHealtText();

        rl.drawTexturePro(self.healthBack, srcBack, dstBack, origin, 0.0, rl.Color.white);
        rl.drawTexturePro(self.healthFront, srcFront, dstFront, origin, 0.0, rl.Color.white);
    }

    fn drawHealtText(self: Self) void {
        var buf: [100]u8 = undefined;

        const health: i32 = @intFromFloat(self.health);
        if (std.fmt.bufPrintZ(&buf, "Health: {d}", .{health})) |text| {
            rl.drawText(text, HEALTH_BAR_X, 70, 20, rl.Color.light_gray);
        } else |_| {}

        if (std.fmt.bufPrintZ(&buf, "Score: {d}", .{self.score})) |text| {
            rl.drawText(text, HEALTH_BAR_X, 45, 20, rl.Color.light_gray);
        } else |_| {}
    }
};
