const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;
const hex = fmt.fmtSliceHexLower;

var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

fn puts(msg: []const u8) void {
    for (msg) |c| {
        const c_ = [2]u16{ c, 0 }; // work around https://github.com/ziglang/zig/issues/4372
        _ = con_out.outputString(@as(*const [1:0]u16, @ptrCast(&c_)));
    }
}

fn printf(buf: []u8, comptime format: []const u8, args: anytype) void {
    puts(fmt.bufPrint(buf, format, args) catch unreachable);
}

pub fn main() void {
    const boot_services = uefi.system_table.boot_services.?;
    const runtime_services = uefi.system_table.runtime_services;
    con_out = uefi.system_table.con_out.?;
    var buf: [40]u8 = undefined;

    var buffer_size: usize = 2;
    var name: [*:0]align(8) u16 = undefined;
    _ = boot_services.allocatePool(uefi.tables.MemoryType.BootServicesData, 2, @as(*[*]align(8) u8, @ptrCast(&name)));
    name[0] = 0;
    var guid: uefi.Guid align(8) = undefined;
    while (true) {
        var name_size = buffer_size;
        switch (runtime_services.getNextVariableName(&name_size, name, &guid)) {
            uefi.Status.Success => {
                printf(buf[0..], "{x:0>8}-{x:0>4}-{x:0>4}-{x:0>2}{x:0>2}{:0>12} ", .{
                    guid.time_low,
                    guid.time_mid,
                    guid.time_high_and_version,
                    guid.clock_seq_high_and_reserved,
                    guid.clock_seq_low,
                    hex(&guid.node),
                });
                _ = con_out.outputString(name);
                puts("\r\n");
            },
            uefi.Status.BufferTooSmall => {
                var alloc: [*:0]align(8) u16 = undefined;
                _ = boot_services.allocatePool(uefi.tables.MemoryType.BootServicesData, name_size, @as(*[*]align(8) u8, @ptrCast(&alloc)));
                for (name[0 .. buffer_size / 2], 0..) |c, i| {
                    alloc[i] = c;
                }
                _ = boot_services.freePool(@as([*]align(8) u8, @ptrCast(name)));
                name = alloc;
                buffer_size = name_size;
            },
            uefi.Status.NotFound => break,
            else => {
                puts("???\r\n");
                break;
            },
        }
    }

    _ = boot_services.freePool(@as([*]align(8) u8, @ptrCast(name)));

    // TODO read some variables

    _ = boot_services.stall(10 * 1000 * 1000);
}
