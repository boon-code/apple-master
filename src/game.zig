const rl = @import("raylib");
const sprite = @import("sprite.zig");

pub const State = struct {
    // Types
    const Self = @This();
    const SpriteSheetUniform = sprite.SpriteSheetUniform;
    const AnimationIndex = sprite.SpriteSheetUniform.Index.Animated;

    // Constants
    const APPLE_FRAME_SPEED = 0.075; // seconds

    // Variables
    backgroundTexture: rl.Texture2D,

    appleSpriteSheet: sprite.SpriteSheetUniform,
    appleAnimIndex: AnimationIndex,
    pos: rl.Vector2,

    delta: f32,
    time: f64,

    // Implementation

    pub fn init() !Self {
        const textureDir = "resources/textures/";
        const backgroundTexture = rl.loadTexture(textureDir ++ "BG.png");
        errdefer rl.unloadTexture(backgroundTexture);

        var appleSpriteSheet = sprite.SpriteSheetUniform.initFromFile(textureDir ++ "AE2.png", 8, 8);
        errdefer appleSpriteSheet.unload();

        var appleAnimIndex = appleSpriteSheet.createIndex(0, 0).createAnimated(APPLE_FRAME_SPEED);

        var pos = rl.Vector2.init(50.0, 50.0);

        return Self{
            .backgroundTexture = backgroundTexture,
            .appleSpriteSheet = appleSpriteSheet,
            .appleAnimIndex = appleAnimIndex,
            .pos = pos,
            .delta = 0,
            .time = rl.getTime(),
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
            self.pos.x -= 20.0 * self.delta * 60.0;
        } else if (rl.isKeyDown(.key_right)) {
            self.pos.x += 20.0 * self.delta * 60.0;
        }
    }

    pub fn updateMovement(self: *Self) void {
        self.appleAnimIndex.update(self.time);
    }

    pub fn draw(self: Self) void {
        rl.drawTexture(self.backgroundTexture, 0.0, 0.0, rl.Color.white);
        self.appleSpriteSheet.draw(self.pos, self.appleAnimIndex.index, .normal);
    }

    pub fn unload(self: Self) void {
        rl.unloadTexture(self.backgroundTexture);
    }
};
