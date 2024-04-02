pub const Level = struct {
    const Self = @This();

    level: i32,
    speed_offset: f32,
    apples_max: i32,
    health_decrease_f: f32,

    pub fn init() Self {
        return Self{
            .level = 1,
            .speed_offset = 0.0,
            .apples_max = 3,
            .health_decrease_f = 0.01,
        };
    }

    pub fn add(self: *Self, change: Change) void {
        self.speed_offset += change.speed_offset;
        self.apples_max += change.apples_max;
        self.health_decrease_f *= change.health_decrease_f;
    }

    pub fn next(self: *Self) void {
        self.level +|= 1;
        inline for (level_changes) |change| {
            if (change.level == self.level) {
                self.add(change);
            }
        }
    }
};

const Change = struct {
    const Self = @This();
    speed_offset: f32,
    apples_max: i32,
    health_decrease_f: f32,
    level: i32,

    pub fn init(level: i32) Self {
        return Self{
            .speed_offset = 0.0,
            .apples_max = 0,
            .health_decrease_f = 1.0,
            .level = level,
        };
    }

    pub fn setSpeed(self: *Self, speed_offset: f32) *Self {
        self.speed_offset = speed_offset;
        return self;
    }

    pub fn setApples(self: *Self, apples_max: i32) *Self {
        self.apples_max = apples_max;
        return self;
    }

    pub fn setDecreaseF(self: *Self, f: f32) *Self {
        self.health_decrease_f = f;
        return self;
    }
};

const level_changes = [_]Change{
    Change.init(2).setApples(1),
    Change.init(3).setSpeed(5.0).setDecreaseF(2.0),
    Change.init(4).setApples(1),
    Change.init(5).setApples(1),
    Change.init(6).setSpeed(5.0).setDecreaseF(2.0),
    Change.init(7).setApples(1),
    Change.init(8).setApples(1),
    Change.init(9).setApples(1),
    Change.init(10).setApples(1),
};
