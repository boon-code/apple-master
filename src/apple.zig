// Everything related to the apples
const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const constants = @import("constants.zig");
const util = @import("util.zig");
const Player = @import("player.zig").Player;
const GameState = @import("game.zig").State;

const AnimatedIndex = sprite.SpriteSheetUniform.Index.Animated;

pub const Apple = struct {
    active: bool,
    position: rl.Vector2,
    anim_index: AnimatedIndex,
    velocity: f32,
    slot: usize,
};

pub const AppleManager = struct {
    const Self = @This();

    const MAX_COUNT = 7;

    debug_sprite_sheet: sprite.SpriteSheetUniform,
    sprite_sheet: sprite.SpriteSheetUniform,
    apples: []Apple,
    allocator: std.mem.Allocator,

    count: i32,
    next_spawn: f64,
    slot_blocked: [constants.APPLE_SLOT_MAX + 1]bool,

    pub fn init(allocator: std.mem.Allocator, time: f64) !Self {
        var apples = try allocator.alloc(Apple, 500);
        errdefer allocator.free(apples);
        for (apples) |*i| {
            i.active = false;
        }

        const debug_sprite_sheet = sprite.SpriteSheetUniform.initFromEmbeddedFile(constants.TEXTURE_DIR ++ "AE4.png", 8, 8);
        const sprite_sheet = sprite.SpriteSheetUniform.initFromEmbeddedFile(constants.TEXTURE_DIR ++ constants.APPLE_PIC, 8, 8);
        var slot_blocked: [constants.APPLE_SLOT_MAX + 1]bool = undefined;
        for (&slot_blocked) |*i| {
            i.* = false;
        }

        return Self{
            .debug_sprite_sheet = debug_sprite_sheet,
            .sprite_sheet = sprite_sheet,
            .apples = apples,
            .allocator = allocator,
            .count = 0,
            .next_spawn = time,
            .slot_blocked = slot_blocked,
        };
    }

    pub fn update(self: *Self, time: f64) void {
        if (self.next_spawn < time) {
            if (self.count < MAX_COUNT) {
                if (self.spawnNew(time)) {
                    std.debug.print("Spawn a new apple: count={d}\n", .{self.count});
                } else |_| {
                    std.debug.print("Delay spawning an apple to next frame: count={d}\n", .{self.count});
                    return; // delay spawning to next frame
                }
            }
            self.next_spawn = time + util.getRandom(f32, constants.APPLE_SPAWN_WAIT_MIN, constants.APPLE_SPAWN_WAIT_MAX);
        }
    }

    pub fn unload(self: *Self) void {
        self.allocator.free(self.apples);
    }

    pub fn drawUpdate(self: *Self, t: f64, delta: f32, player: Player, state: *GameState) void {
        var num = self.count;
        for (self.apples) |*i| {
            if (num <= 0) {
                return;
            }
            if (i.active) {
                num -= 1;
                i.velocity += constants.GRAVITY * delta * constants.FPS;
                const inc = i.velocity * delta * constants.FPS;
                i.position.y += inc;

                _ = i.anim_index.update(t);

                if (player.catchesApple(i.position, inc)) {
                    i.active = false;
                    self.slot_blocked[i.slot] = false;
                    self.count -= 1;
                    state.caugthApple(i);
                    std.debug.print("Caught apple: count={d}\n", .{self.count});
                } else {
                    if (state.isDebug()) {
                        self.debug_sprite_sheet.draw(i.position, i.anim_index.index, .normal);
                    } else {
                        self.sprite_sheet.draw(i.position, i.anim_index.index, .normal);
                    }

                    if (i.position.y > constants.SCREEN_Y_APPLES_MAX) {
                        i.active = false;
                        self.slot_blocked[i.slot] = false;
                        self.count -= 1;
                        state.missedApple(i);
                        std.debug.print("Removed apple: count={d}\n", .{self.count});
                    }
                }
            }
        }
        unreachable;
    }

    fn spawnNew(self: *Self, time: f64) !void {
        var apple = self.nextUnused();
        const spriteIndex = rl.getRandomValue(0, 7);
        const slot = try self.nextSlot();
        const posX: f32 = util.f32FromInt(slot) * constants.APPLE_SLOT_WIDTH + constants.SLOT_OFFSET_X;
        apple.slot = slot;
        apple.position = rl.Vector2.init(posX, -constants.APPLE_HEIGHT);
        apple.anim_index = self.sprite_sheet.createIndex(spriteIndex, 0).createAnimated(constants.APPLE_ANIMATION_SPEED, time);
        apple.velocity = util.getRandom(f32, constants.APPLE_START_SPEED_MIN, constants.APPLE_START_SPEED_MAX);
        apple.active = true;

        self.slot_blocked[slot] = true;

        self.count += 1;
    }

    fn nextSlot(self: *Self) !usize {
        var slot: usize = @intCast(rl.getRandomValue(constants.APPLE_SLOT_MIN, constants.APPLE_SLOT_MAX));
        if (self.slot_blocked[slot]) {
            return error.SlotIsBlocked;
        }
        return slot;
    }

    fn nextUnused(self: *Self) *Apple {
        for (self.apples) |*i| {
            if (!i.active) {
                return i;
            }
        }
        @panic("Expect to always have room left in the array");
    }
};
