const Builder = @import("std").build.Builder;
const Target = @import("std").build.Target;
const CrossTarget = @import("std").build.CrossTarget;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const exe = b.addExecutable("bootx64", "main.zig");
    exe.setBuildMode(b.standardReleaseOptions());
    exe.setTheTarget(Target{
        .Cross = CrossTarget{
            .arch = builtin.Arch.x86_64,
            .os = builtin.Os.uefi,
            .abi = builtin.Abi.msvc,
        },
    });
    exe.setOutputDir("efi/boot");
    b.default_step.dependOn(&exe.step);
}
