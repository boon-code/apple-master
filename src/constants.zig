pub const TEXTURE_DIR = "resources/textures/";

// screen layout
pub const SCREEN_X_AREA = 835;
pub const SCREEN_X_APPLES_MAX = SCREEN_X_AREA - APPLE_WIDTH;
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

// plus
pub const PLUS_WIDTH = 14;
pub const PLUS_HEIGHT = 14;
pub const PLUS_ANIM_SPEED = 0.025;
pub const PLUS_WAIT_FIRST = 0.125;
