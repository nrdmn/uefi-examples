const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;

var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

fn puts(msg: []const u8) void {
    for (msg) |c| {
        _ = con_out.outputString(&[_]u16{ c, 0 });
    }
}

fn printf(buf: []u8, comptime format: []const u8, args: ...) void {
    puts(fmt.bufPrint(buf, format, args) catch unreachable);
}

pub fn main() void {
    const boot_services = uefi.system_table.boot_services.?;
    const runtime_services = uefi.system_table.runtime_services;
    con_out = uefi.system_table.con_out.?;
    var buf: [40]u8 = undefined;

    var name_size: usize = 2;
    var buffer_size: usize = 2;
    var name: [*]u16 = &[_]u16{0};
    var guid: uefi.Guid align(8) = undefined;
    while (true) {
        switch (runtime_services.getNextVariableName(&name_size, name, &guid)) {
            uefi.status.success => {
                printf(buf[0..], "{x:0>8}-{x:0>4}-{x:0>4}-{x:0>2}{x:0>2}{x:0>12} ", guid.time_low, guid.time_mid, guid.time_high_and_version, guid.clock_seq_high_and_reserved, guid.clock_seq_low, guid.node);
                _ = con_out.outputString(name);
                puts("\r\n");
                name_size = buffer_size;
            },
            uefi.status.buffer_too_small => {
                var alloc: [*]u16 = undefined;
                _ = boot_services.allocatePool(uefi.tables.MemoryType.BootServicesData, name_size, @ptrCast(*[*]u8, &alloc));
                for (name[0 .. buffer_size / 2]) |c, i| {
                    alloc[i] = c;
                }
                name = alloc;
                // TODO free old buffer
                buffer_size = name_size;
            },
            uefi.status.not_found => break,
            else => unreachable,
        }
    }

    // TODO read some variables

    _ = boot_services.stall(10 * 1000 * 1000);
}
