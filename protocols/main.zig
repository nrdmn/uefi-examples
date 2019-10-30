const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;

// Assigned in main().
var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

// We need to print each character in an [_]u8 individually because EFI
// encodes strings as UCS-2.
fn puts(msg: []const u8) void {
    for (msg) |c| {
        _ = con_out.outputString(&[_]u16{ c, 0 });
    }
}

fn printf(buf: []u8, comptime format: []const u8, args: ...) void {
    puts(fmt.bufPrint(buf, format, args) catch unreachable);
}

pub const SimpleNetworkProtocol = extern struct {
    revision: u64,
    _start: extern fn (*const SimpleNetworkProtocol) usize,
    _stop: extern fn (*const SimpleNetworkProtocol) usize,
    _initialize: extern fn (*const SimpleNetworkProtocol, usize, usize) usize,
    // TODO

    /// Changes the state of a network interface from "stopped" to "started".
    pub fn start(self: *const SimpleNetworkProtocol) usize {
        return self._start(self);
    }

    /// Changes the state of a network interface from "started" to "stopped".
    pub fn stop(self: *const SimpleNetworkProtocol) usize {
        return self._stop(self);
    }

    /// Resets a network adapter and allocates the transmit and receive buffers required by the network interface.
    pub fn initialize(self: *const SimpleNetworkProtocol, extra_rx_buffer_size: usize, extra_tx_buffer_size: usize) usize {
        return self._initialize(self, extra_rx_buffer_size, extra_tx_buffer_size);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0xa19832b9,
        .time_mid = 0xac25,
        .time_high_and_version = 0x11d3,
        .clock_seq_high_and_reserved = 0x9a,
        .clock_seq_low = 0x2d,
        .node = [_]u8{ 0x00, 0x90, 0x27, 0x3f, 0xc1, 0x4d },
    };
};

pub fn main() void {
    con_out = uefi.system_table.con_out.?;
    const boot_services = uefi.system_table.boot_services.?;

    _ = con_out.reset(false);

    // We're going to use this buffer to format strings.
    var buf: [100]u8 = undefined;

    const mnp align(8) = uefi.Guid{
        .time_low = 0x7ab33a91,
        .time_mid = 0xace5,
        .time_high_and_version = 0x4326,
        .clock_seq_high_and_reserved = 0xb5,
        .clock_seq_low = 0x72,
        .node = [_]u8{ 0xe7, 0xee, 0x33, 0xd3, 0x9f, 0x16 },
    };

    var no_handles: usize = undefined;
    var handles: [*]uefi.Handle = undefined;
    var status: usize = undefined;
    var i: usize = undefined;

    puts("locating handles for snp...\r\n");
    status = boot_services.locateHandleBuffer(uefi.tables.LocateSearchType.ByProtocol, &SimpleNetworkProtocol.guid, null, &no_handles, &handles);
    printf(buf[0..], "locateHandleBuffer returned {}\r\n", status);
    printf(buf[0..], "no_handles = {}\r\n", no_handles);
    i = 0;
    while (i < no_handles) : (i += 1) {
        printf(buf[0..], "handles[{}] = {}\r\n", i, handles[i]);
        var proto: *SimpleNetworkProtocol align(8) = undefined;
        const s = boot_services.handleProtocol(handles[i], &SimpleNetworkProtocol.guid, @ptrCast(*?*c_void, &proto));
        printf(buf[0..], "handleProtocol returned {}\r\n", s);
        if (s == uefi.status.success) {
            printf(buf[0..], "revision = {x}\r\n", proto.revision);
            printf(buf[0..], "start() = {}\r\n", proto.start());
            printf(buf[0..], "initialize() = {}\r\n", proto.initialize(65536, 65536));
            printf(buf[0..], "stop() = {}\r\n", proto.stop());
        }
        puts("\r\n");
    }
    if (status == uefi.status.success) {
        status = boot_services.freePool(@ptrCast(*[*]u8, handles));
        printf(buf[0..], "freePool returned {}\r\n", status);
    }

    puts("\r\n\r\n\r\n");
    _ = boot_services.stall(2 * 1000 * 1000);

    puts("locating handles for mnp...\r\n");
    status = boot_services.locateHandleBuffer(uefi.tables.LocateSearchType.ByProtocol, &mnp, null, &no_handles, &handles);
    printf(buf[0..], "locateHandleBuffer returned {}\r\n", status);
    printf(buf[0..], "no_handles = {}\r\n", no_handles);
    i = 0;
    while (i < no_handles) : (i += 1) {
        printf(buf[0..], "handles[{}] = {}\r\n", i, handles[i]);
    }
    if (status == uefi.status.success) {
        status = boot_services.freePool(@ptrCast(*[*]u8, handles));
        printf(buf[0..], "freePool returned {}\r\n", status);
    }

    _ = boot_services.stall(10 * 1000 * 1000);
}
