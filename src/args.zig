const std = @import("std");

pub const CommandLineOptions = struct {
    pub const GuiType = enum { Cli, Gui };
    custom_asset_path: ?[]u8 = null,
    gui_type: GuiType = .Gui,

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
