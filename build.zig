const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep = b.path("vendor");

    // ##### luajit #####

    const luajit = dep.path(b, "luajit2");
    const luajitSrc = luajit.path(b, "src");
    const luajitLib = luajitSrc.path(b, "libluajit.a");

    const make = b.addSystemCommand(&.{ "make", "BUILDMODE=static", "amalg" });
    make.setCwd(luajit);

    if (target.result.isDarwin()) {
        const deploymentTarget = std.fmt.allocPrint(b.allocator, "{}", .{
            target.result.os.getVersionRange().semver.min,
        }) catch @panic("OOM");
        make.setEnvironmentVariable("MACOSX_DEPLOYMENT_TARGET", deploymentTarget);
    }

    // ##### main executable #####

    const exe = b.addExecutable(.{
        .name = "zl",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    exe.addIncludePath(luajitSrc);
    exe.step.dependOn(&make.step);

    if (target.result.os.tag == .linux) {
        exe.root_module.linkSystemLibrary("m", .{});
        exe.root_module.linkSystemLibrary("unwind", .{});
    }
    exe.addObjectFile(luajitLib);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
