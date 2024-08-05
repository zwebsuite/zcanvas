const std = @import("std");

const CFlags = &.{};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // create demo executable
    const exe = b.addExecutable(.{
        .name = "zcanvas",
        .root_source_file = b.path("demo/demo.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // link SDL to demo
    exe.linkSystemLibrary("SDL2");
    // include SDL wrapper to demo
    exe.addIncludePath(b.path("demo/"));
    exe.addCSourceFile(.{
        .file = b.path("demo/sdllib.c"),
        .flags = CFlags,
    });
    
    // add zcanvas module
    const module_zcanvas = b.createModule(.{
        .root_source_file = b.path("src/zcanvas.zig"),
        .target = target,
        .optimize = optimize
    });
    exe.root_module.addImport("zcanvas", module_zcanvas);

    // add vexlib modules
    const module_vexlib = b.createModule(.{
        .root_source_file = b.path("../vexlib/"++"src/vexlib.zig"),
        .target = target,
        .optimize = optimize
    });
    module_zcanvas.addImport("vexlib", module_vexlib);
    exe.root_module.addImport("vexlib", module_vexlib);

    b.installArtifact(exe);
}
