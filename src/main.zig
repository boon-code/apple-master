const rl = @import("raylib");
const std = @import("std");
const builtin = @import("builtin");
const sprite = @import("sprite.zig");
const game = @import("game.zig");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screen_width = 1024;
    const screen_height = 768;

    rl.initWindow(screen_width, screen_height, "Apple Master Revived");
    defer rl.closeWindow(); // Close window and OpenGL context

    const allocator = initAllocator();
    var game_state = try game.State.init(allocator);
    defer game_state.unload();

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    rl.hideCursor();
    defer rl.showCursor();

    rl.setExitKey(.key_q);
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        game_state.updateTime();

        if (rl.isKeyPressed(.key_f)) {
            std.debug.print("Key f was pressed\n", .{});
            rl.toggleFullscreen();
            std.debug.print("Toggled fullscreen mode\n", .{});
        }
        game_state.updateKeys();
        game_state.updateHealth();
        game_state.updateMovement();
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        game_state.draw();

        rl.drawFPS(20, 20);
        //----------------------------------------------------------------------------------
    }
}

inline fn initAllocator() std.mem.Allocator {
    if ((builtin.os.tag == .wasi) or true) {
        var buffer: [7000]u8 = undefined; // roughly (emperic)
        var fbo = std.heap.FixedBufferAllocator.init(&buffer);
        return fbo.allocator();
    } else {
        var gpo = std.heap.GeneralPurposeAllocator(.{}){};
        return gpo.allocator();
    }
}
