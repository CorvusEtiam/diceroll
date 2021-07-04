const CommandLineOptions = @import("../args.zig").CommandLineOptions;

const State = @import("../main.zig").State;

const ray = @import("../c.zig").ray;
const dice = @import("./dice.zig");

pub fn start(options: CommandLineOptions, state: *State) !void {
    _ = options;
    ray.InitWindow(640, 480, "Dice Roller");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);
    state.forceReroll();
    while (!ray.WindowShouldClose()) {
        if ( ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON) ) {
            state.forceReroll();
        }
        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.DARKGREEN);
        dice.renderDices(&state.dices);
    }
}