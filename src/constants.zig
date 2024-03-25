pub const TEXTURE_DIR = "resources/textures/";

// screen layout
pub const SCREEN_X_APPLES_MAX = 835 - APPLE_WIDTH;
pub const SCREEN_Y_APPLES_MAX = 768 - (APPLE_HEIGHT * 2 / 3);
pub const APPLE_HEIGHT = 68;
pub const APPLE_WIDTH = 68;
pub const APPLE_ANIMATION_SPEED: f32 = 0.1;

pub const FPS: f32 = 60.0;
pub const APPLE_START_SPEED_MIN: f32 = 0.1;
pub const APPLE_START_SPEED_MAX: f32 = 1.0;
pub const APPLE_SPAWN_WAIT_MIN: f32 = -7.0; // just change the odds
pub const APPLE_SPAWN_WAIT_MAX: f32 = 5.0;

pub const GRAVITY = 1.0;

pub const APPLE_SLOT_MAX = @divFloor(SCREEN_X_APPLES_MAX, APPLE_WIDTH);
pub const APPLE_SLOT_MIN = 0;
