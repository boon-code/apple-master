pub const TEXTURE_DIR = "resources/textures/";

// target FPS
const INITIAL_FPS: f32 = 60.0;
pub var FPS: f32 = INITIAL_FPS;

// screen layout
pub const SCREEN_X_AREA = 835;
pub const SCREEN_X_APPLES_MAX = SCREEN_X_AREA - APPLE_WIDTH;
pub const SCREEN_Y_APPLES_MAX = 768 - (APPLE_HEIGHT * 2 / 3);
pub const HEALTH_BAR_X = 870.0;

// apple
pub const APPLE_PIC = "AE3.png";
pub const APPLE_HEIGHT = 68;
pub const APPLE_HEIGHT_ACTUAL = APPLE_HEIGHT - APPLE_OFFSET_Y_TOP - APPLE_OFFSET_Y_BOTTOM;
pub const APPLE_WIDTH = 65;
pub const APPLE_OFFSET_X = 4; // on both sides
pub const APPLE_OFFSET_Y_TOP = 14;
pub const APPLE_OFFSET_Y_BOTTOM = 7;
pub const APPLE_ANIMATION_SPEED: f32 = 0.1;

pub const APPLE_START_SPEED_MIN: f32 = 0.1;
pub const APPLE_START_SPEED_MAX: f32 = 1.0;
pub const APPLE_SPAWN_WAIT_MIN: f32 = 0.1; // just change the odds
pub const APPLE_SPAWN_WAIT_MAX: f32 = 1.5;

pub const GRAVITY: f32 = 1.0 / INITIAL_FPS;

pub const SLOT_OFFSET_X = 1;
pub const APPLE_SLOT_WIDTH = APPLE_WIDTH + SLOT_OFFSET_X * 2;
pub const APPLE_SLOT_MAX = @divFloor(SCREEN_X_APPLES_MAX, APPLE_SLOT_WIDTH);
pub const APPLE_SLOT_MIN = 0;

// plus
pub const PLUS_WIDTH = 26;
pub const PLUS_HEIGHT = 26;
pub const PLUS_ANIM_SPEED = 0.025;
pub const PLUS_WAIT_FIRST = 0.125;
pub const PLUS_OFFSET_Y = APPLE_OFFSET_Y_TOP + @divFloor(APPLE_HEIGHT_ACTUAL - PLUS_HEIGHT, 2);

// basket
pub const BASKET_WIDTH = 141;
pub const BASKET_SPEED_NORMAL = 10.0;
pub const BASKET_SPEED_FAST = 30.0;
