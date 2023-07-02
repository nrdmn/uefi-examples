const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;

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
    con_out = uefi.system_table.con_out.?;
    const boot_services = uefi.system_table.boot_services.?;
    var buf: [256]u8 = undefined;

    var memory_map: [*]uefi.tables.MemoryDescriptor = undefined;
    var memory_map_size: usize = 0;
    var memory_map_key: usize = undefined;
    var descriptor_size: usize = undefined;
    var descriptor_version: u32 = undefined;
    // Fetch the memory map.
    // Careful! Every call to boot services can alter the memory map.
    while (uefi.Status.BufferTooSmall == boot_services.getMemoryMap(&memory_map_size, memory_map, &memory_map_key, &descriptor_size, &descriptor_version)) {
        // allocatePool is the UEFI equivalent of malloc. allocatePool may
        // alter the size of the memory map, so we must check the return
        // value of getMemoryMap every time.
        if (uefi.Status.Success != boot_services.allocatePool(uefi.tables.MemoryType.BootServicesData, memory_map_size, @as(*[*]align(8) u8, @ptrCast(&memory_map)))) {
            return;
        }
    }

    // You'll need memory_map_key to call exitBootServices().

    var i: usize = 0;
    while (i < memory_map_size / descriptor_size) : (i += 1) {
        // See the UEFI specification for more information on the attributes.
        printf(buf[0..], "*** {:3} type={s:23} physical=0x{x:0>16} virtual=0x{x:0>16} pages={:16} uc={} wc={} wt={} wb={} uce={} wp={} rp={} xp={} nv={} more_reliable={} ro={} sp={} cpu_crypto={} memory_runtime={}\r\n", .{
            i,
            @tagName(memory_map[i].type),
            memory_map[i].physical_start,
            memory_map[i].virtual_start,
            memory_map[i].number_of_pages,
            @intFromBool(memory_map[i].attribute.uc),
            @intFromBool(memory_map[i].attribute.wc),
            @intFromBool(memory_map[i].attribute.wt),
            @intFromBool(memory_map[i].attribute.wb),
            @intFromBool(memory_map[i].attribute.uce),
            @intFromBool(memory_map[i].attribute.wp),
            @intFromBool(memory_map[i].attribute.rp),
            @intFromBool(memory_map[i].attribute.xp),
            @intFromBool(memory_map[i].attribute.nv),
            @intFromBool(memory_map[i].attribute.more_reliable),
            @intFromBool(memory_map[i].attribute.ro),
            @intFromBool(memory_map[i].attribute.sp),
            @intFromBool(memory_map[i].attribute.cpu_crypto),
            @intFromBool(memory_map[i].attribute.memory_runtime),
        });
    }

    _ = boot_services.stall(10 * 1000 * 1000);
}
