const std = @import("std");
const prompt = @import("./prompt.zig");
const c = @import("./c.zig");
const ray = c.ray;
const dice = @import("./dice.zig");

pub const GameScreen = enum {
    StartMenu,
    GameWinMenu,
    GameStatsMenu,
    Turn,
};

fn computePoints(dices: []u8) u32 {
    var faces_counter: [6]u8 = .{0} ** 6;
    var points: u32 = 0;
    for (dices) |dice_val| {
        faces_counter[dice_val - 1] += 1;
    }
    switch (faces_counter[0]) {
        0, 1, 2 => {
            points += faces_counter[0] * 100;
        },
        3 => {
            points += 1000;
        },
        4 => {
            points += 2000;
        },
        5 => {
            points += 4000;
        },
        else => @panic("Faces count cannot be bigger than 5"),
    }
    points += faces_counter[4] * 50;

    for (faces_counter[1..5]) |face_count, index| {
        const face: u32 = @intCast(u32, index) + 2;
        switch (face_count) {
            0, 1, 2 => {},
            3 => {
                points += face * 100;
            },
            4 => {
                points += 2 * face * 100;
            },
            5 => {
                points += 4 * face * 100;
            },
            else => @panic("Face count cannot be bigger than 5!"),
        }
    }

    // check straight
    var has_low_straight: bool = true;
    for (faces_counter[0..4]) |face| {
        if (face != 1) {
            has_low_straight = false;
            break;
        }
    }
    if (has_low_straight) {
        points += 1250;
    }

    return points;
}

pub const Player = struct {
    is_human: bool = false,
    name: []const u8 = undefined,
    points: u32 = 0,
    pub fn deinit(self: *Player, alloc: *std.mem.Allocator) void {
        alloc.free(self.name);
    }
};

pub const State = struct {
    current_game_screen: GameScreen = .StartMenu,
    players: []Player = undefined,
    current_player: usize = 0,
    dices: [5]u8 = .{0} ** 5,
    reroll_buffer: [5]bool = [_]bool{true} ** 5,
    reroll_count: usize = 0,

    pub fn getCurrentPlayer(self: *State) *Player {
        return &self.players[self.current_player];
    }

    pub fn init(alloc: *std.mem.Allocator, user: []const u8, player_count: usize) !State {
        var arr = std.ArrayList(Player).init(alloc);
        try arr.append(.{ .name = try alloc.dupe(u8, user), .points = 0, .is_human = true });

        {
            var idx: usize = 1;
            while (idx < player_count) : ({
                idx += 1;
            }) {
                try arr.append(Player{
                    .name = try std.fmt.allocPrint(alloc, "Player {d}", .{idx}),
                    .points = 0,
                    .is_human = false,
                });
            }
        }

        return State{
            .players = arr.toOwnedSlice(),
            .current_player = 0,
        };
    }

    pub fn deinit(self: *State, alloc: *std.mem.Allocator) void {
        for (self.players) |*player| {
            player.deinit(alloc);
        }
        alloc.free(self.players);
    }

    pub fn reroll(self: *State) void {
        for (self.reroll_buffer) |dice_to_reroll, idx| {
            if (dice_to_reroll) {
                self.dices[idx] = rng.random.intRangeAtMost(u8, 1, 6);
            }
        }

        self.reroll_count = dicesToReroll(&self.dices, &self.reroll_buffer);
    }
};

pub const AppError = error{BadInput};

const WINNING_CONDITION: usize = 10000;

fn dicesToReroll(dices: []u8, reroll: *[5]bool) usize {
    var face_counter = [_]u8{0} ** 6;
    // if dices is not 1 or 5 or not contribute to small straight or 3,4,5 of each\
    for (dices) |elem, index| {
        face_counter[elem - 1] += 1;
        if ((elem == 1) or (elem == 5)) {
            reroll[index] = false;
        }
    }
    for (face_counter) |face_count, face_index| {
        const face = face_index + 1;
        if (face_count >= 3) {
            for (dices) |elem, idx| {
                if (elem == face) {
                    reroll[idx] = false;
                }
            }
        }
    }
    var has_straight: bool = true;
    for (face_counter[0..4]) |face| {
        if (face != 1) {
            has_straight = false;
            break;
        }
    }
    if (has_straight) {
        for (reroll) |*r| {
            r.* = false;
        }
        return 0;
    }
    var count: u8 = 0;
    for (reroll) |r| {
        if (r) count += 1;
    }
    return count;
}

pub fn rerollDices(dices: *[5]u8, reroll: []bool) void {
    for (reroll) |dice_to_reroll, idx| {
        if (dice_to_reroll) {
            dices[idx] = rng.random.intRangeAtMost(u8, 1, 6);
        }
    }
}

pub fn doComputerTurn(state: *State) void {
    const current = state.getCurrentPlayer();
    var dices: [5]u8 = undefined;
    var reroll_buf = [_]bool{true} ** 5;
    rerollDices(&dices, &reroll_buf);
    var points = computePoints(&dices);
    std.debug.print("Computer rolled: {any}. It has {d} points.\n", .{ dices, points });
    var dices_to_reroll = dicesToReroll(&dices, &reroll_buf);
    while (dices_to_reroll > 0) {
        rerollDices(&dices, &reroll_buf);
        points = computePoints(&dices);
        std.debug.print("Computer rolls again {d} dices. It has {any} points.\n", .{ dices_to_reroll, points });
        dices_to_reroll = dicesToReroll(&dices, &reroll_buf);
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

    var dices: [5]u8 = undefined;
    var reroll_buf = [_]bool{true} ** 5;
    rerollDices(&dices, &reroll_buf);
    std.debug.print("You rolled: {any}\n", .{dices});
    var points = computePoints(&dices);
    std.debug.print("You have got {d} points\n", .{points});
    var dices_to_reroll = dicesToReroll(&dices, &reroll_buf);
    while (dices_to_reroll > 0) {
        std.debug.print("You can reroll {d} dices.\n ", .{dices_to_reroll});
        const choice = prompt.boolean("Do you want to reroll them? y/n:") catch false;
        if (!choice) return;
        rerollDices(&dices, &reroll_buf);
        points = computePoints(&dices);
        std.debug.print("You have got {d} points\n", .{points});
        dices_to_reroll = dicesToReroll(&dices, &reroll_buf);
    }

    current.points += points;
    std.debug.print("After turn player {s} has {d} points.\n", .{ current.name, current.points });
}

pub fn won(game_state: *State) bool {
    return game_state.getCurrentPlayer().points >= WINNING_CONDITION;
}

const RandState = struct {
    rng: std.rand.DefaultPrng = undefined,
    random: *std.rand.Random = undefined,
};

var rng: RandState = .{};

pub fn initRandomGenerator() void {
    var seed_bytes: [@sizeOf(u64)]u8 = undefined;
    std.crypto.random.bytes(&seed_bytes);
    const seed: u64 = std.mem.readIntNative(u64, &seed_bytes);
    rng.rng = std.rand.DefaultPrng.init(seed);
    rng.random = &rng.rng.random;
}

pub const CommandLineOptions = struct {
    pub const GuiType = enum { Cli, Gui };
    custom_asset_path: ?[]u8 = null,
    gui_type: GuiType = .Cli,

    pub fn deinit(self: *CommandLineOptions, alloc: *std.mem.Allocator) void {
        if (self.custom_asset_path) |asset| {
            alloc.free(asset);
        }
    }
};

pub fn parseArgs(alloc: *std.mem.Allocator) !CommandLineOptions {
    var cmd: CommandLineOptions = .{};
    var args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    for (args) |argument, index| {
        if (std.mem.eql(u8, argument, "-t") or std.mem.eql(u8, argument, "--type")) {
            if (index < args.len) {
                if (std.mem.eql(u8, args[index + 1], "gui")) {
                    cmd.gui_type = .Gui;
                } else {
                    cmd.gui_type = .Cli;
                }
            }
        } else if (std.mem.eql(u8, argument, "-a") or std.mem.eql(u8, argument, "--asset")) {
            if (index < args.len) {
                cmd.custom_asset_path = try alloc.dupe(u8, args[index + 1]);
            }
        }
    }

    std.debug.print("Command Line Arguments: gui-kind={any}, custom-asset-path={s}\n", .{ cmd.gui_type, cmd.custom_asset_path });

    return cmd;
}

pub fn main() anyerror!void {
    std.debug.print("== Hello in this little dice roller == \n", .{});
    std.debug.print("First things first.\n", .{});
    initRandomGenerator();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var state = try State.init(&gpa.allocator, "User", 2);
    defer state.deinit(&gpa.allocator);
    var options = try parseArgs(&gpa.allocator);
    defer options.deinit(&gpa.allocator);

    switch (options.gui_type) {
        .Cli => {
            try startCli(options, &state);
        },
        .Gui => {
            try startGui(options, &state);
        },
    }
}

pub fn startCli(options: CommandLineOptions, state: *State) !void {
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

pub fn startGui(options: CommandLineOptions, state: *State) !void {
    _ = options;
    _ = state;

    ray.InitWindow(640, 480, "Dice Roller");
    defer ray.CloseWindow();
    ray.SetTargetFPS(30);

    state.reroll();
    std.debug.print("DICE := {any}\n", .{ state.dices });
    while (!ray.WindowShouldClose()) {
        // handle click:
        if ( ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON) ) {
            for ( state.reroll_buffer ) | *el | {
                el.* = true;
            }
            state.reroll();
        }

        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.DARKGREEN);
        for ( state.dices ) | elem, idx | {
            dice.renderDice(elem, @intCast(i32, idx));
        }
    }
}
