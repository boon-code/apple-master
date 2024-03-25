const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const util = @import("util.zig");

const f32FromInt = util.f32FromInt;

pub const State = struct {
    // Types
    const Self = @This();
    const SpriteSheetUniform = sprite.SpriteSheetUniform;
    const SpriteIndex = sprite.SpriteSheetUniform.Index;
    const AnimationIndex = sprite.SpriteSheetUniform.Index.Animated;

    // Constants
    const APPLE_FRAME_SPEED = 0.075; // seconds

    // Sprites
    backgroundTexture: rl.Texture2D,

    appleSpriteSheet: sprite.SpriteSheetUniform,
    appleAnimIndex: AnimationIndex,
    pos: rl.Vector2,

    healthBack: rl.Texture2D,
    healthFront: rl.Texture2D,

    delta: f32,
    time: f64,
    health: f32,

    // Implementation

    pub fn init() !Self {
        const textureDir = "resources/textures/";
        const backgroundTexture = rl.loadTexture(textureDir ++ "BG.png");
        errdefer rl.unloadTexture(backgroundTexture);

        // Apple sprite
        const appleSpriteSheet = sprite.SpriteSheetUniform.initFromFile(textureDir ++ "AE2.png", 8, 8);
        errdefer appleSpriteSheet.unload();
        const appleAnimIndex = appleSpriteSheet.createIndex(0, 0).createAnimated(APPLE_FRAME_SPEED);
        const pos = rl.Vector2.init(50.0, 50.0);

        // Health bar
        const healthBack = rl.loadTexture(textureDir ++ "STR1.png");
        errdefer rl.unloadTexture(healthBack);
        const healthFront = rl.loadTexture(textureDir ++ "STR2.png");
        errdefer rl.unloadTexture(healthFront);
        std.debug.assert(healthBack.width == healthFront.width);
        std.debug.assert(healthBack.height == healthFront.height);


        return Self{
            .backgroundTexture = backgroundTexture,
            .appleSpriteSheet = appleSpriteSheet,
            .appleAnimIndex = appleAnimIndex,
            .pos = pos,
            .healthBack = healthBack,
            .healthFront = healthFront,
            .delta = 0,
            .time = rl.getTime(),
            .health = 100.0,
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
            self.pos.x -= 5.0 * self.delta * 60.0;
        } else if (rl.isKeyDown(.key_right)) {
            self.pos.x += 5.0 * self.delta * 60.0;
        }

        if (rl.isKeyDown(.key_m)) {
            self.health -= 1.0;
            if (self.health < 0.0) {
                self.health = 0.0;
            }
        } else if (rl.isKeyDown(.key_p)) {
            self.health += 1.0;
            if (self.health > 100.0) {
                self.health = 100.0;
            }
        }
    }

    pub fn updateMovement(self: *Self) void {
        self.appleAnimIndex.update(self.time);
    }

    pub fn draw(self: Self) void {
        var buf: [100:0]u8 = undefined;
        // Background
        rl.drawTexture(self.backgroundTexture, 0.0, 0.0, rl.Color.white);
        if (std.fmt.bufPrintZ(&buf, "Position: {d}", .{self.pos.x})) |text| {
            rl.drawText(text, 0, 100, 20, rl.Color.light_gray);
        } else |_| {}

        self.drawHealthBar();

        // Apple
        self.appleSpriteSheet.draw(self.pos, self.appleAnimIndex.index, .normal);
    }

    pub fn unload(self: *Self) void {
        rl.unloadTexture(self.backgroundTexture);
        rl.unloadTexture(self.healthBack);
        rl.unloadTexture(self.healthFront);
        self.appleSpriteSheet.unload();
        self.healthSpriteSheet.unload();
    }

    fn drawHealthBar(self: Self) void {
        const frameWidth = f32FromInt(self.healthBack.width);
        const frameHeight = f32FromInt(self.healthBack.height);
        const origin = rl.Vector2.init(0.0, 0.0);
        const dstWidth = frameWidth * 2.0;
        const dstHeight = frameHeight * 2.0;
        // Back
        const dstBack = rl.Rectangle.init(860.0, 100.0, dstWidth, dstHeight);
        const srcBack = rl.Rectangle.init(0, 0, frameWidth, frameHeight);
        // Front
        const f = (100.0 - self.health) / 100.0;
        var srcDy = frameHeight * f;
        var dstDy = dstHeight * f;
        const dstFront = rl.Rectangle.init(dstBack.x, dstBack.y + dstDy, dstWidth, dstHeight - dstDy);
        const srcFront = rl.Rectangle.init(0, srcDy, frameWidth, frameHeight - srcDy);

        rl.drawTexturePro(self.healthBack, srcBack, dstBack, origin, 0.0, rl.Color.white);
        rl.drawTexturePro(self.healthFront, srcFront, dstFront, origin, 0.0, rl.Color.white);
    }
};
