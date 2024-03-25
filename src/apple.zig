// Everything related to the apples
const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const constants = @import("constants.zig");
const util = @import("util.zig");

const AnimatedIndex = sprite.SpriteSheetUniform.Index.Animated;

const Apple = struct {
    active: bool,
    position: rl.Vector2,
    appleAnimIndex: AnimatedIndex,
    velocity_y: f32,
};

pub const AppleManager = struct {
    const Self = @This();

    const MAX_COUNT = 7;

    appleSpriteSheet: sprite.SpriteSheetUniform,
    apples: []Apple,
    allocator: std.mem.Allocator,

    count: i32,
    nextSpawn: f64,

    pub fn init(allocator: std.mem.Allocator) !Self {
        var apples = try allocator.alloc(Apple, 500);
        errdefer allocator.free(apples);
        for (apples) |*i| {
            i.active = false;
        }

        const appleSpriteSheet = sprite.SpriteSheetUniform.initFromFile(constants.TEXTURE_DIR ++ "AE2.png", 8, 8);

        return Self{
            .appleSpriteSheet = appleSpriteSheet,
            .apples = apples,
            .allocator = allocator,
            .count = 0,
            .nextSpawn = rl.getTime(),
        };
    }

    pub fn update(self: *Self, t: f64) void {
        if (self.nextSpawn < t) {
            if (self.count < MAX_COUNT) {
                self.spawnNew();
                std.debug.print("Spawn a new apple: count={d}\n", .{self.count});
            }
            self.nextSpawn = t + 0.5;
        }
    }

    pub fn unload(self: *Self) void {
        self.allocator.free(self.apples);
    }

    pub fn drawUpdate(self: *Self, t: f64, delta: f32) void {
        var num = self.count;
        for (self.apples) |*i| {
            if (i.active) {
                i.velocity_y += constants.GRAVITY * delta;
                i.position.y += i.velocity_y * delta * constants.FPS;

                i.appleAnimIndex.update(t);

                self.appleSpriteSheet.draw(i.position, i.appleAnimIndex.index, .normal);

                if (i.position.y > constants.SCREEN_Y_APPLES_MAX) {
                    i.active = false;
                    self.count -= 1;
                    std.debug.print("Removed apple: count={d}\n", .{self.count});
                }
                num -= 1;
                if (num <= 0) {
                    return;
                }
            }
        }
    }

    fn spawnNew(self: *Self) void {
        var apple = self.nextUnused();
        const spriteIndex = rl.getRandomValue(0, 7);
        const posX: f32 = util.f32FromInt(rl.getRandomValue(constants.APPLE_SLOT_MIN, constants.APPLE_SLOT_MAX)) * constants.APPLE_WIDTH;
        apple.position = rl.Vector2.init(posX, -constants.APPLE_HEIGHT);
        apple.appleAnimIndex = self.appleSpriteSheet.createIndex(spriteIndex, 0).createAnimated(constants.APPLE_ANIMATION_SPEED);
        apple.velocity_y = util.getRandom(f32, constants.APPLE_START_SPEED_MIN, constants.APPLE_START_SPEED_MAX);
        apple.active = true;

        self.count += 1;
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
