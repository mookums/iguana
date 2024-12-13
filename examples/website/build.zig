const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const website = b.addExecutable(.{
        .name = "website",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zzz = b.dependency("zzz", .{
        .target = target,
        .optimize = optimize,
    }).module("zzz");

    website.root_module.addImport("zzz", zzz);

    const install_artifact = b.addInstallArtifact(website, .{});
    b.getInstallStep().dependOn(&install_artifact.step);

    const run_artifact = b.addRunArtifact(website);
    run_artifact.step.dependOn(&install_artifact.step);

    const run_step = b.step("run", "Run website");
    run_step.dependOn(&install_artifact.step);
    run_step.dependOn(&run_artifact.step);
}
