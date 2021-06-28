const std = @import("std");

pub const PromptError = error {
    PromptBadInput
};

pub fn forNumber(comptime prompt: []const u8) !usize {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    _ = try stdout.write(prompt);
    var buffer: [32]u8 = undefined;
    const size = try stdin.read(&buffer);
    const line = std.mem.trimRight(u8, buffer[0..size], "\r\n");
    return try std.fmt.parseUnsigned(usize, line, 10);
}

pub fn forEnter() void {
    const stdin = std.io.getStdIn().reader();
    const byte = stdin.readByte() catch unreachable;
    while (byte != '\r') {
        std.debug.print("Press Enter to continue...\n", .{});
    }
    return;
}
pub fn boolean(comptime prompt: []const u8) !bool {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    _ = try stdout.write(prompt);
    var buffer: [16]u8 = undefined;
    const size = try stdin.read(&buffer);
    const line = std.mem.trimRight(u8, buffer[0..size], "\r\n");
    if (line.len == 0) return PromptError.PromptBadInput;

    // _ = try stdout.write("\n");
    if (line[0] == 'y' or line[0] == 'Y') {
        return true;
    }
    if (line[0] == 'n' or line[0] == 'N') {
        return false;
    }

    return PromptError.PromptBadInput;
}
