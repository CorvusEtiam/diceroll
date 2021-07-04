const std = @import("std");
const ray = @import("../c.zig").ray;

const State = @import("./ui.zig").State;

const DICE_FACES = [6]u8{
    0b0000_1000, // :1
    0b0100_0001, // :2
    0b0100_1001, // :3
    0b0101_0101, // :4
    0b0101_1101, // :5
    0b0111_0111, // :6
};


const DOT_OFFSET = [7]ray.Vector2 {
    .{ .x = -1.0, .y = -1.0 }, // 1 dot
    .{ .x =  0.0, .y = -1.0 }, // 2 dot
    .{ .x =  1.0, .y = -1.0 }, // 3 dot 
    .{ .x =  0.0, .y =  0.0 }, // 4 dot
    .{ .x = -1.0, .y =  1.0 }, // 5 dot
    .{ .x =  0.0, .y =  1.0 }, // 6 dot
    .{ .x =  1.0, .y =  1.0 }, // 7 dot
};

const DICE_SIZE: i32 = 64;


pub fn renderDice(dice: u8, position: usize, marked: bool) void {
    var dice_rect = ray.Rectangle { 
        .x = @intToFloat(f32, (position * (DICE_SIZE + 12))) + 24.0,
        .y = 24.0,
        .width = 64.0,
        .height = 64.0 
    };
    if ( marked ) {
        const outline = .{ .x = dice_rect.x - 1.0, .y = dice_rect.y - 1.0, .width = dice_rect.width + 1.0, .height = dice_rect.height + 1.0 };
        ray.DrawRectangleRoundedLines(outline, 0.2, 1, 4, ray.YELLOW);
    }

    ray.DrawRectangleRounded(dice_rect, 0.1, 1, ray.RED);

    {
        var center_of_die = dice_rect.center();
        var dice_face_pattern = DICE_FACES[dice - 1];
        var bit_index: usize = 0;
        while ( bit_index < 7 ) {
            if ( (dice_face_pattern & 0x01) != 0 ) { // is bit set
                const offset = DOT_OFFSET[bit_index];
                
                const dot = ray.Vector2Add(center_of_die,  ray.Vector2Scale(offset, 16.0));
                ray.DrawCircleV(dot, 6, ray.WHITE);
            }

            bit_index += 1;
            dice_face_pattern = dice_face_pattern >> 1;
        }
    }
} 

pub fn renderDices(state: *const State) void {
    for ( state.dices ) | dice, index | {
        renderDice(dice, index, state.reroll_buffer[index]);
    }
}