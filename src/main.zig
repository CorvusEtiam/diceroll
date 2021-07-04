const std = @import("std");
const gui = @import("./gui/ui.zig");
const cli = @import("./cli/ui.zig");
const args = @import("./args.zig");

pub const Player = struct {
    is_human: bool = false,
    name: []const u8 = undefined,
    points: u32 = 0,
    pub fn deinit(self: *Player, alloc: *std.mem.Allocator) void {
        alloc.free(self.name);
    }
};

pub const State = struct {
    players: []Player = undefined,
    current_player: usize = 0,
    dices: [5]u8 = .{0} ** 5,
    reroll_buffer: [5]bool = [_]bool{true} ** 5,
    reroll_count: usize = 0,

    pub fn nextPlayer(self: *State) void {
        return;
    }

    pub fn getCurrentPlayer(self: *State) *Player {
        return &self.players[self.current_player];
    }

    pub fn dicesToReroll(self: *State) usize {
        var face_counter = [_]u8{0} ** 6;
        // if dices is not 1 or 5 or not contribute to small straight or 3,4,5 of each\
        for (self.dices) |elem, index| {
            face_counter[elem - 1] += 1;
            if ((elem == 1) or (elem == 5)) {
                self.reroll_buffer[index] = false;
            }
        }
        for (face_counter) |face_count, face_index| {
            const face = face_index + 1;
            if (face_count >= 3) {
                for (self.dices) |elem, idx| {
                    if (elem == face) {
                        self.reroll_buffer[idx] = false;
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
            for (self.reroll_buffer) |*r| {
                r.* = false;
            }
            return 0;
        }
        var count: u8 = 0;
        for (self.reroll_buffer) |r| {
            if (r) count += 1;
        }
        return count;
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

    pub fn computePoints(self: *State) u32 {
        var faces_counter: [6]u8 = .{0} ** 6;
        var points: u32 = 0;
        for (self.dices) |dice_val| {
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

    pub fn reroll(self: *State) void {
        for (self.reroll_buffer) |dice_to_reroll, idx| {
            if (dice_to_reroll) {
                self.dices[idx] = global_rng.random.intRangeAtMost(u8, 1, 6);
            }
        }
        const asc_u8 = comptime std.sort.asc(u8);
        std.sort.sort(u8, &self.dices, {}, asc_u8);
        self.reroll_count = self.dicesToReroll();
    }

    pub fn forceReroll(self: *State) void {
        std.mem.set(bool, &self.reroll_buffer, true);
        self.reroll();
    }
};

pub const AppError = error{BadInput};

const WINNING_CONDITION: usize = 10000;

const RandState = struct {
    rng: std.rand.DefaultPrng = undefined,
    random: *std.rand.Random = undefined,
};

pub var global_rng: RandState = .{};
pub var global_allocator : *std.mem.Allocator = undefined;


pub fn initRandomGenerator() void {
    var seed_bytes: [@sizeOf(u64)]u8 = undefined;
    std.crypto.random.bytes(&seed_bytes);
    const seed: u64 = std.mem.readIntNative(u64, &seed_bytes);
    global_rng.rng = std.rand.DefaultPrng.init(seed);
    global_rng.random = &global_rng.rng.random;
}

pub fn main() anyerror!void {
    std.debug.print("== Hello in this little dice roller == \n", .{});
    std.debug.print("First things first.\n", .{});
    initRandomGenerator();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    global_allocator = &gpa.allocator;
    var state = try State.init(&gpa.allocator, "User", 2);
    defer state.deinit(&gpa.allocator);
    var options = try args.parseArgs(&gpa.allocator);
    defer options.deinit(&gpa.allocator);

    switch (options.gui_type) {
        .Cli => {
            try cli.start(options, &state);
        },
        .Gui => {
            try gui.start(options, &state);
        },
    }
}
