const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // Tests
    {
        const lib_test = b.addTest("lib/tests.zig");
        lib_test.setTarget(target);
        lib_test.setBuildMode(mode);
        linkLibGit(lib_test, target);
        const lib_test_step = b.step("test_lib", "Run the lib tests");
        lib_test_step.dependOn(&lib_test.step);

        const sample_test = b.addTest("sample/main.zig");
        sample_test.setTarget(target);
        sample_test.setBuildMode(mode);
        addLibGit(sample_test, target, "");
        const sample_test_step = b.step("test_sample", "Run the sample tests");
        sample_test_step.dependOn(&sample_test.step);

        const test_step = b.step("test", "Run all the tests");
        test_step.dependOn(&lib_test.step);
        test_step.dependOn(&sample_test.step);

        b.default_step = test_step;
    }

    // Sample
    {
        const sample_exe = b.addExecutable("sample", "sample/main.zig");
        sample_exe.setTarget(target);
        sample_exe.setBuildMode(mode);
        sample_exe.install();
        addLibGit(sample_exe, target, "");

        const run_cmd = sample_exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the sample");
        run_step.dependOn(&run_cmd.step);
    }
}

pub fn addLibGit(exe: *std.build.LibExeObjStep, target: std.build.Target, comptime prefix_path: []const u8) void {
    if (prefix_path.len > 0 and !std.mem.endsWith(u8, prefix_path, "/")) @panic("prefix-path must end with '/' if it is not empty");

    const git_pkg = std.build.Pkg{
        .name = "git",
        .path = .{ .path = prefix_path ++ "lib/git.zig" },
    };

    exe.addPackage(git_pkg);

    linkLibGit(exe, target);
}

fn linkLibGit(exe: *std.build.LibExeObjStep, target: std.build.Target) void {
    _ = target;

    exe.linkLibC();
    exe.linkSystemLibrary("git2");
}
