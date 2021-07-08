const std = @import("std");

const ray = @import("../c.zig").ray;
const main = @import("../main.zig");
const dice = @import("./dice.zig");

const CommandLineOptions = @import("../args.zig").CommandLineOptions;
pub const State = main.State;

pub const GameScreenId = enum {
    MainMenu,
    Game,
    WinScreen,
};

var global_font: ray.Font = undefined;

pub const Button = struct {
    const ButtonState = enum {
        idle,
        hovered,
        pressed,
    };

    label: []const u8 = undefined,
    rect: ray.Rectangle,
    active: bool = true,
    state: ButtonState = .idle,

    pub fn handle(self: *Button) bool {
        if (!self.active) {
            return false;
        }

        const mouse = ray.GetMousePosition();
        if (ray.CheckCollisionPointRec(mouse, self.rect)) {
            if (ray.IsMouseButtonDown(ray.MOUSE_LEFT_BUTTON)) {
                self.state = .pressed;
            } else {
                self.state = .hovered;
            }

            if (ray.IsMouseButtonReleased(ray.MOUSE_LEFT_BUTTON)) {
                self.state = .idle;
                return true;
            } else {
                return false;
            }
        } else {
            self.state = .idle;
            return false;
        }
    }

    pub fn draw(self: *Button) void {
        var color: ray.Color = blk: {
            if (!self.active) break :blk ray.GRAY;
            switch (self.state) {
                .pressed => break :blk ray.YELLOW,
                .hovered => break :blk ray.ORANGE,
                .idle => break :blk ray.RED,
            }
        };

        ray.DrawRectangleRounded(self.rect, 0.2, 1, color);
        ray.DrawTextEx(global_font, self.label.ptr, .{ .x = self.rect.x + 8.0, .y = self.rect.y + 8.0 }, 24.0, 1.0, ray.BLACK);
    }
};

var start_game_button: Button = Button{
    .label = "Start Game",
    .rect = .{ .x = 200.0, .y = 200, .width = 200.0, .height = 80.0 },
};
var reroll_button: Button = Button{
    .label = "Reroll",
    .rect = .{ .x = 100.0, .y = 200, .width = 150.0, .height = 80.0 },
};
var end_game: Button = Button{
    .label = "End Game",
    .rect = .{ .x = 400.0, .y = 200, .width = 150.0, .height = 80.0 },
};

pub fn mainMenu(state: *State) GameScreenId {
    var result: GameScreenId = .MainMenu;
    if (start_game_button.handle()) {
        state.forceReroll();
        result = .Game;
    }

    ray.BeginDrawing();
    ray.ClearBackground(ray.BLACK);
    start_game_button.draw();
    ray.EndDrawing();

    return result;
}

fn gameScreen(state: *State) GameScreenId {
    var result: GameScreenId = .Game;
    if (reroll_button.handle()) {
        state.reroll();
    }
    if (end_game.handle()) {
        result = .WinScreen;
    }

    ray.BeginDrawing();
    ray.ClearBackground(ray.DARKGREEN);
    reroll_button.draw();
    end_game.draw();
    dice.renderDices(state);
    ray.EndDrawing();
    return result;
}

pub fn start(options: CommandLineOptions, state: *State) !void {
    _ = options;
    ray.InitWindow(640, 480, "Dice Roller");
    defer ray.CloseWindow();
    ray.SetTargetFPS(60);

    global_font = ray.LoadFontEx("resources/arial.ttf", 24, 0, 256);
    defer ray.UnloadFont(global_font);

    var game_screen_id: GameScreenId = .MainMenu;
    var first_turn: bool = true;

    while (!ray.WindowShouldClose()) {
        switch (game_screen_id) {
            .MainMenu => {
                state.newGame(state.player.name);
                game_screen_id = mainMenu(state);
                first_turn = true;
            },
            .Game => {
                if (first_turn) {
                    state.forceReroll();
                    first_turn = false;
                } 
                game_screen_id = gameScreen(state);
            },
            .WinScreen => {
                game_screen_id = mainMenu(state);
            },
        }
    }
}
