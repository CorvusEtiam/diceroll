const std = @import("std");

const pkgs = struct {
    const bearssl = std.build.Pkg {
        .name = "zig-bearssl",
        .path = .{ .path = "./externals/zig-bearssl/src/lib.zig" }
    };
};

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("diceroll", "src/main.zig");

    if (exe.target.isWindows()) {
        exe.addVcpkgPaths(.dynamic) catch @panic("vcpkg not found");
        exe.linkSystemLibrary("raylib");
        exe.linkSystemLibrary("c");
    }

    // exe.addPackage(pkgs.raylib)
    // exe.addPackage(pkgs.bearssl);

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const gui_cmd = exe.run();
    gui_cmd.step.dependOn(b.getInstallStep());
    if ( b.args ) | args | {
        gui_cmd.addArgs(args);
    }
    gui_cmd.addArg("-t");
    gui_cmd.addArg("gui");

    const gui_step = b.step("gui", "Run the gui app");
    gui_step.dependOn(&gui_cmd.step);
}
