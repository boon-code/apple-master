const rl = @import("raylib");
const std = @import("std");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Apple Master Revived");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    rl.setExitKey(.key_q);
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        if (rl.isKeyPressed(.key_f)) {
            std.debug.print("Key f was pressed\n", .{});
            rl.toggleFullscreen();
            std.debug.print("Toggled fullscreen mode", .{});
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        rl.drawText("Apple Master!", 200, 100, 20, rl.Color.light_gray);
        rl.drawFPS(20, 20);
        //----------------------------------------------------------------------------------
    }
}
