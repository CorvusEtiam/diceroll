const std = @import("std");
const gui = @import("./gui/ui.zig");
const cli = @import("./cli/ui.zig");
const args = @import("./args.zig");

const patternMatch = @import("./patterns.zig").patternMatch;

// const layout = @import("./gui/layout.zig");
// 
// comptime {
//     std.testing.refAllDecls(layout);
// }

pub const Player = struct {
    name: []const u8 = undefined,
    points: u32 = 0,
};

pub const State = struct {
    player: Player = undefined,
    alloc: *std.mem.Allocator = undefined,
    dices: [5]u8 = .{0} ** 5,
    reroll_buffer: [5]bool = [_]bool{true} ** 5,
    reroll_count: usize = 0,
    

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
        
        // var points: usize = 0;
        // const three_of = patternMatch(self.dices, "NNN??") or patternMatch(self.dices, "?NNN?") or patternMatch(dices, "??NNN"); // { value: u8, count: u8 }
        // const four_of = patternMatch(self.dices, "NNNN?") or patternMatch(self.dices, "?NNNN");
        // const five_of = patternMatch(self.dices, "NNNNN");
        // const many = dices[2];
        // if ( five_of ) { points = many * 100 * 4; } else if (four_of) { points = many * 100 * 2; } else if ( three_of ) { points = many * 100; }
        // const has_straight = patternMatch(dices, "12345") or patternMatch(dices, "23456");
        
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

    pub fn init(user: []const u8) State {
        return .{
            .player = .{ .name = user, .points = 0 },
        };
    }

    pub fn computePoints(self: *State) u32 {
        var points: u32 = 0;
        const three_of = patternMatch(&self.dices, "NNN??") or patternMatch(&self.dices, "?NNN?") or patternMatch(&self.dices, "??NNN");
        const four_of = patternMatch(&self.dices, "NNNN?") or patternMatch(&self.dices, "?NNNN");
        const five_of = patternMatch(&self.dices, "NNNNN");
        const ones = @intCast(u32, std.mem.count(u8, &self.dices, &.{1}));
        const fives = @intCast(u32, std.mem.count(u8, &self.dices, &.{5}));
        
        const multiple_factor: u32 = if (self.dices[3] == 1) 1000 else 100;

        if ( five_of ) {
            points += self.dices[3] * multiple_factor * 4;
        } else if ( four_of ) {
            points += self.dices[3] * multiple_factor * 2;
        } else if ( three_of ) {
            points += self.dices[3] * multiple_factor;
        }
        
        if ( ones < 3 ) {
            points += ones * 100;
        }
        if ( fives < 3 ) {
            points += fives * 50;
        }
        if ( patternMatch(&self.dices, "12345") or patternMatch(&self.dices, "23456")) {
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

    pub fn newGame(self: *State, player_name: []const u8) void {
        self.player = Player {
            .name = player_name,
        };
        std.mem.set(bool, &self.reroll_buffer, true);
        std.mem.set(u8, &self.dices, 1);
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
    var state = State.init("User");
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
