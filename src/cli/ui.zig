
const std = @import("std");
const prompt = @import("./prompt.zig");
const rng = @import("../main.zig").rng;
const State = @import("../main.zig").State;
const CommandLineOptions = @import("../args.zig").CommandLineOptions;


fn doComputerTurn(state: *State) void {
    const current = state.getCurrentPlayer();
    state.reroll();
    var points = state.computePoints();
    std.debug.print("Computer rolled: {any}. It has {d} points.\n", .{ state.dices, points });
    var dices_to_reroll = state.dicesToReroll();
    while (dices_to_reroll > 0) {
        state.reroll();
        points = state.computePoints();
        std.debug.print("Computer rolls again {d} dices. It has {any} points.\n", .{ dices_to_reroll, points });
        dices_to_reroll = state.dicesToReroll();
    }
    std.debug.print("Computer finally got {d} points.\n", .{points});
    current.points += points;
}

// 1. Generate first dice set
//  1a. If reroll is possible: add reroll button
//  1b. Add Next Player button
//
// When computer

pub fn doTurn(state: *State) void {
    const current = state.getCurrentPlayer();
    if (!current.is_human) {
        return doComputerTurn(state);
    }

    state.forceReroll();
    std.debug.print("You rolled: {any}\n", .{state.dices});
    var points = state.computePoints();
    std.debug.print("You have got {d} points\n", .{points});
    var dices_to_reroll = state.dicesToReroll();
    while (dices_to_reroll > 0) {
        std.debug.print("You can reroll {d} dices.\n ", .{dices_to_reroll});
        const choice = prompt.boolean("Do you want to reroll them? y/n:") catch false;
        if (!choice) return;
        state.reroll();
        points = state.computePoints();
        std.debug.print("You have got {d} points\n", .{points});
        dices_to_reroll = state.dicesToReroll();
    }

    current.points += points;
    std.debug.print("After turn player {s} has {d} points.\n", .{ current.name, current.points });
}

fn won(game_state: *State) bool {
    return game_state.getCurrentPlayer().points >= WINNING_CONDITION;
}


pub fn start(options: CommandLineOptions, state: *State) !void {
    _ = options;
    while (true) {
        // turn starts here
        const choice: bool = prompt.boolean("Do you want to roll dices? y/n: ") catch false;
        if (!choice) {
            break;
        }
        doTurn(state);
        state.current_player = (state.current_player + 1) % state.players.len;
    }
}
