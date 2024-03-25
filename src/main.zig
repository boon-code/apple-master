const rl = @import("raylib");
const std = @import("std");
const sprite = @import("sprite.zig");

const APPLE_FRAME_SPEED = 0.075; // seconds

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1024;
    const screenHeight = 768;

    rl.initWindow(screenWidth, screenHeight, "Apple Master Revived");
    defer rl.closeWindow(); // Close window and OpenGL context

    const textureDir = "resources/textures/";
    const backgroundTexture = rl.loadTexture(textureDir ++ "BG.png");
    defer rl.unloadTexture(backgroundTexture);

    var appleSpriteSheet = sprite.SpriteSheetUniform.initFromFile(textureDir ++ "AE2.png", 8, 8);
    defer appleSpriteSheet.unload();
    var appleAnimIndex = appleSpriteSheet.createIndex(0, 0).createAnimated(APPLE_FRAME_SPEED);

    var pos = rl.Vector2.init(50.0, 50.0);

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var lastTime: f64 = rl.getTime();
    rl.setExitKey(.key_q);
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        const t = rl.getTime();
        const delta: f32 = @floatCast(t - lastTime);
        _ = delta;
        if (rl.isKeyPressed(.key_f)) {
            std.debug.print("Key f was pressed\n", .{});
            rl.toggleFullscreen();
            std.debug.print("Toggled fullscreen mode", .{});
        }
        if (rl.isKeyPressed(.key_down)) {
            appleAnimIndex.index.nextSprite();
        } else if (rl.isKeyPressed(.key_up)) {
            appleAnimIndex.index.previousSprite();
        }

        appleAnimIndex.update(t);

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);
        rl.drawTexture(backgroundTexture, 0.0, 0.0, rl.Color.white);

        appleSpriteSheet.draw(pos, appleAnimIndex.index, .normal);

        rl.drawText("Apple Master!", 500, 100, 20, rl.Color.light_gray);
        rl.drawFPS(20, 20);
        //----------------------------------------------------------------------------------
    }
}
