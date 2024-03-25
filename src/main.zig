const rl = @import("raylib");
const std = @import("std");
const sprite = @import("sprite.zig");
const game = @import("game.zig");

const APPLE_FRAME_SPEED = 0.075; // seconds

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1024;
    const screenHeight = 768;

    rl.initWindow(screenWidth, screenHeight, "Apple Master Revived");
    defer rl.closeWindow(); // Close window and OpenGL context

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var gameState = try game.State.init(allocator);

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    rl.hideCursor();
    defer rl.showCursor();

    rl.setExitKey(.key_q);
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        gameState.updateTime();

        if (rl.isKeyPressed(.key_f)) {
            std.debug.print("Key f was pressed\n", .{});
            rl.toggleFullscreen();
            std.debug.print("Toggled fullscreen mode", .{});
        }
        gameState.updateKeys();
        gameState.updateMovement();
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        gameState.draw();

        rl.drawText("Apple Master!", 500, 100, 20, rl.Color.light_gray);
        rl.drawText("Press q to quit", 500, 125, 20, rl.Color.light_gray);

        rl.drawFPS(20, 20);
        //----------------------------------------------------------------------------------
    }
}
