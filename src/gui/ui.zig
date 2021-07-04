const std = @import("std");

const ray = @import("../c.zig").ray;
const main = @import("../main.zig");
const dice = @import("./dice.zig");

const CommandLineOptions = @import("../args.zig").CommandLineOptions;
pub const State = main.State;


pub const ButtonInfo = struct {
    isEnabled: bool = true,
};

pub const WidgetInfo = union(enum) {
    buttonInfo: ButtonInfo, 
};

pub const UiState = struct {
    alloc: *std.mem.Allocator = undefined,
    widgets_info: std.StringHashMap(WidgetInfo) = undefined,
    font: ray.Font = undefined,

    pub fn initFont() ray.Font {
        return ray.LoadFontEx("resources/arial.ttf", 24, 0, 250);
    }

    pub fn init(alloc: *std.mem.Allocator) UiState {
        return .{
            .font = UiState.initFont(),
            .alloc = alloc,
            .widgets_info = std.StringHashMap(WidgetInfo).init(alloc)
        };
    }
};

pub var ui_state: UiState = .{};

pub fn renderLabel(label: []const u8, position: ray.Vector2, uid: []const u8, color: ray.Color) void {
    _ = uid;
    ray.DrawTextEx(ui_state.font, label.ptr, position, 24.0, 1, color);
}

pub fn renderButton(label: []const u8, button_rect: ray.Rectangle, uid: [] const u8) bool {
    const mouse = ray.GetMousePosition();
    var state_found = ui_state.widgets_info.getOrPut(uid) catch unreachable;
    if ( !state_found.found_existing ) {
        state_found.value_ptr.buttonInfo = .{ .isEnabled = true };
    }
    var button_state: *WidgetInfo = state_found.value_ptr;

    
    const mouse_over_button = ray.CheckCollisionPointRec(mouse, button_rect);

    var result = ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON) and mouse_over_button;
    
    const text_vec = ray.Vector2 { .x = button_rect.x + 8.0, .y = button_rect.y + 8.0 };
    
    if ( !button_state.buttonInfo.isEnabled ) {
        ray.DrawRectangleRounded(button_rect, 0.1, 1, ray.DARKGRAY);
    } else {
        if ( mouse_over_button ) {
            ray.DrawRectangleRounded(button_rect, 0.1, 1, ray.BLUE);
        } else {
            ray.DrawRectangleRounded(button_rect, 0.1, 1, ray.DARKBLUE);
        }
    }
    ray.DrawTextEx(ui_state.font, label.ptr, text_vec, 24.0, 2.0, ray.WHITE);

    return button_state.buttonInfo.isEnabled and result;
}



pub fn start(options: CommandLineOptions, state: *State) !void {
    _ = options;
    ray.InitWindow(640, 480, "Dice Roller");
    defer ray.CloseWindow();
    ui_state = UiState.init(main.global_allocator);
    ray.SetTargetFPS(60);
    state.forceReroll();
    try ui_state.widgets_info.put("new_turn_btn_0", WidgetInfo { .buttonInfo = .{ .isEnabled = false } });

    while (!ray.WindowShouldClose()) {
        if ( renderButton("Reroll", .{ .x = 300.0, .y = 200.0, .width = 120.0, .height = 60.0 }, "reroll_btn_0")) {
            state.reroll(); 
        }
        if ( renderButton("Next Turn", .{ .x = 450.0, .y = 200.0, .width = 150.0, .height = 60.0 }, "new_turn_btn_0")) {
            // switch player
            state.nextPlayer();
            state.forceReroll(); 
        }

        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.DARKGREEN);
        if ( state.getCurrentPlayer().is_human ) {
            renderLabel("Turn: Player", .{ .x = 50.0, .y = 230.0 }, "player_lbl", ray.YELLOW);
        } else {
            renderLabel("Turn: Computer", .{ .x = 50.0, .y = 230.0 }, "computer_lbl", ray.WHITE);
        }
        dice.renderDices(state);
    }
}