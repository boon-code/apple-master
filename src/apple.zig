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
    appleAnimIndex: AnimatedIndex,
    velocity: f32,
    slot: usize,
};

pub const AppleManager = struct {
    const Self = @This();

    const MAX_COUNT = 7;

    debugSpriteSheet: sprite.SpriteSheetUniform,
    appleSpriteSheet: sprite.SpriteSheetUniform,
    apples: []Apple,
    allocator: std.mem.Allocator,

    count: i32,
    nextSpawn: f64,
    slotBlocked: [constants.APPLE_SLOT_MAX + 1]bool,

    pub fn init(allocator: std.mem.Allocator) !Self {
        var apples = try allocator.alloc(Apple, 500);
        errdefer allocator.free(apples);
        for (apples) |*i| {
            i.active = false;
        }

        const debugSpriteSheet = sprite.SpriteSheetUniform.initFromFile(constants.TEXTURE_DIR ++ "AE4.png", 8, 8);
        const appleSpriteSheet = sprite.SpriteSheetUniform.initFromFile(constants.TEXTURE_DIR ++ constants.APPLE_PIC, 8, 8);
        var slotBlocked: [constants.APPLE_SLOT_MAX + 1]bool = undefined;
        for (&slotBlocked) |*i| {
            i.* = false;
        }

        return Self{
            .debugSpriteSheet = debugSpriteSheet,
            .appleSpriteSheet = appleSpriteSheet,
            .apples = apples,
            .allocator = allocator,
            .count = 0,
            .nextSpawn = rl.getTime(),
            .slotBlocked = slotBlocked,
        };
    }

    pub fn update(self: *Self, t: f64) void {
        if (self.nextSpawn < t) {
            if (self.count < MAX_COUNT) {
                if (self.spawnNew()) {
                    std.debug.print("Spawn a new apple: count={d}\n", .{self.count});
                } else |_| {
                    std.debug.print("Delay spawning an apple to next frame: count={d}\n", .{self.count});
                    return; // delay spawning to next frame
                }
            }
            self.nextSpawn = t + util.getRandom(f32, constants.APPLE_SPAWN_WAIT_MIN, constants.APPLE_SPAWN_WAIT_MAX);
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

                _ = i.appleAnimIndex.update(t);

                if (player.catchesApple(i.position, inc)) {
                    i.active = false;
                    self.slotBlocked[i.slot] = false;
                    self.count -= 1;
                    state.caugthApple(i);
                    std.debug.print("Caught apple: count={d}\n", .{self.count});
                } else {
                    if (state.isDebug()) {
                        self.debugSpriteSheet.draw(i.position, i.appleAnimIndex.index, .normal);
                    } else {
                        self.appleSpriteSheet.draw(i.position, i.appleAnimIndex.index, .normal);
                    }

                    if (i.position.y > constants.SCREEN_Y_APPLES_MAX) {
                        i.active = false;
                        self.slotBlocked[i.slot] = false;
                        self.count -= 1;
                        state.missedApple(i);
                        std.debug.print("Removed apple: count={d}\n", .{self.count});
                    }
                }
            }
        }
        unreachable;
    }

    fn spawnNew(self: *Self) !void {
        var apple = self.nextUnused();
        const spriteIndex = rl.getRandomValue(0, 7);
        const slot = try self.nextSlot();
        const posX: f32 = util.f32FromInt(slot) * constants.APPLE_SLOT_WIDTH + constants.SLOT_OFFSET_X;
        apple.slot = slot;
        apple.position = rl.Vector2.init(posX, -constants.APPLE_HEIGHT);
        apple.appleAnimIndex = self.appleSpriteSheet.createIndex(spriteIndex, 0).createAnimated(constants.APPLE_ANIMATION_SPEED);
        apple.velocity = util.getRandom(f32, constants.APPLE_START_SPEED_MIN, constants.APPLE_START_SPEED_MAX);
        apple.active = true;

        self.slotBlocked[slot] = true;

        self.count += 1;
    }

    fn nextSlot(self: *Self) !usize {
        var slot: usize = @intCast(rl.getRandomValue(constants.APPLE_SLOT_MIN, constants.APPLE_SLOT_MAX));
        if (self.slotBlocked[slot]) {
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
