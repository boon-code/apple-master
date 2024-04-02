const level_changes = [_]Change{
    Change.init(2).setApples(2).setNeeded(3),
    Change.init(3).setSpeed(5.0).setDecreaseF(2.0),
    Change.init(4).setApples(1).setNeeded(4),
    Change.init(5).setApples(1).setNeeded(5),
    Change.init(6).setSpeed(5.0).setDecreaseF(2.0).setNeeded(-10),
    Change.init(7).setApples(1).setNeeded(2),
    Change.init(8).setApples(1).setNeeded(2),
    Change.init(9).setApples(1),
    Change.init(10).setApples(1).setNeeded(10),
};

pub const Level = struct {
    const Self = @This();

    level: i32,
    speed_offset: f32,
    apples_max: i32,
    health_decrease_f: f32,
    needed_apples: i64,
    caught_apples: i64,

    pub fn init() Self {
        return Self{
            .level = 1,
            .speed_offset = 0.0,
            .apples_max = 3,
            .health_decrease_f = 0.01,
            .caught_apples = 0,
            .needed_apples = 5,
        };
    }

    pub fn appleCaught(self: *Self) void {
        self.caught_apples +|= 1;
        if (self.caught_apples >= self.needed_apples) {
            self.next();
        }
    }

    fn add(self: *Self, change: Change) void {
        self.speed_offset += change.speed_offset;
        self.apples_max += change.apples_max;
        self.health_decrease_f *= change.health_decrease_f;
        self.needed_apples += change.needed_apples;
    }

    fn next(self: *Self) void {
        self.level +|= 1;
        inline for (level_changes) |change| {
            if (change.level == self.level) {
                self.add(change);
            }
        }
        self.needed_apples += self.caught_apples;
    }
};

const Change = struct {
    const Self = @This();
    speed_offset: f32,
    apples_max: i32,
    health_decrease_f: f32,
    level: i32,
    needed_apples: i64,

    pub fn init(level: i32) Self {
        return Self{
            .speed_offset = 0.0,
            .apples_max = 0,
            .health_decrease_f = 1.0,
            .level = level,
            .needed_apples = 0,
        };
    }

    pub fn setSpeed(self: Self, speed_offset: f32) Self {
        var x = self;
        x.speed_offset = speed_offset;
        return x;
    }

    pub fn setApples(self: Self, apples_max: i32) Self {
        var x = self;
        x.apples_max = apples_max;
        return x;
    }

    pub fn setDecreaseF(self: Self, f: f32) Self {
        var x = self;
        x.health_decrease_f = f;
        return x;
    }

    pub fn setNeeded(self: Self, apple_count: i64) Self {
        var x = self;
        x.needed_apples = apple_count;
        return x;
    }
};
