pub const texture_dir = "resources/textures/";

// target FPS
pub const fps: f32 = 60.0;

// screen layout
const screen_x_area = 835;
const screen_x_apples_max = screen_x_area - apple_width;
pub const screen_y_apples_max = 768 - (apple_height * 2 / 3);
pub const health_bar_x = 870.0;

// apple
pub const apple_pic = "AE3.png";
pub const apple_height = 68;
const apple_height_actual = apple_height - apple_offset_y_top - apple_offset_y_bottom;
pub const apple_width = 65;
pub const apples_width = apple_width * 8;
pub const apples_height = apple_height * 8;
pub const apple_offset_x = 4; // on both sides
const apple_offset_y_top = 14;
const apple_offset_y_bottom = 7;
pub const apple_animation_speed: f32 = 0.1;

pub const apple_start_speed_min: f32 = 0.1;
pub const apple_start_speed_max: f32 = 1.0;
pub const apple_spawn_wait_min: f32 = 0.1; // just change the odds
pub const apple_spawn_wait_max: f32 = 1.5;

pub const gravity: f32 = 1.0 / fps;

pub const slot_offset_x = 1;
pub const apple_slot_width = apple_width + slot_offset_x * 2;
pub const apple_slot_max = @divFloor(screen_x_apples_max, apple_slot_width);
pub const apple_slot_min = 0;

// plus
pub const plus_width = 26;
pub const plus_height = 26;
pub const plus_anim_count = 18;

pub const plus_anim_speed = 0.025;
pub const plus_wait_first = 0.125;
pub const plus_offset_y = apple_offset_y_top + @divFloor(apple_height_actual - plus_height, 2);

// basket
pub const basket_width = 141;
pub const basket_height = 14;
pub const basket_speed_normal = 10.0;
pub const basket_speed_fast = 30.0;

// background
pub const bg_width = 1024;
pub const bg_height = 768;

// health bar
pub const bar_width = 57;
pub const bar_height = 61;
