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
    _reset: extern fn (*const SimpleNetworkProtocol, bool) usize,
    _shutdown: extern fn (*const SimpleNetworkProtocol) usize,
    _receive_filters: extern fn (*const SimpleNetworkProtocol, u32, u32, bool, usize, ?[*]const MacAddress) usize,
    _station_address: usize, // TODO
    _statistics: usize, // TODO
    _mcast_ip_to_mac: usize, // TODO
    _nvdata: usize, // TODO
    _get_status: usize, // TODO
    _transmit: extern fn (*const SimpleNetworkProtocol, usize, usize, [*]const u8, ?*const MacAddress, ?*const MacAddress, ?*const u16) usize,
    _receive: extern fn (*const SimpleNetworkProtocol, ?*usize, *usize, [*]u8, ?*MacAddress, ?*MacAddress, ?*u16) usize,
    wait_for_packet: uefi.Event,
    mode: *SimpleNetworkMode,

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

    /// Resets a network adapter and reinitializes it with the parameters that were provided in the previous call to initialize().
    pub fn reset(self: *const SimpleNetworkProtocol, extended_verification: bool) usize {
        return self._reset(self, extended_verification);
    }

    /// Resets a network adapter and leaves it in a state that is safe for another driver to initialize.
    pub fn shutdown(self: *const SimpleNetworkProtocol) usize {
        return self._shutdown(self);
    }

    /// Manages the multicast receive filters of a network interface.
    pub fn receiveFilters(self: *const SimpleNetworkProtocol, enable: u32, disable: u32, reset_mcast_filter: bool, mcast_filter_cnt: usize, mcast_filter: ?[*]const MacAddress) usize {
        return self._receive_filters(self, enable, disable, reset_mcast_filter, mcast_filter_cnt, mcast_filter);
    }

    /// Places a packet in the transmit queue of a network interface.
    pub fn transmit(self: *const SimpleNetworkProtocol, header_size: usize, buffer_size: usize, buffer: [*]const u8, src_addr: ?*const MacAddress, dest_addr: ?*const MacAddress, protocol: ?*const u16) usize {
        return self._transmit(self, header_size, buffer_size, buffer, src_addr, dest_addr, protocol);
    }

    /// Receives a packet from a network interface.
    pub fn receive(self: *const SimpleNetworkProtocol, header_size: ?*usize, buffer_size: *usize, buffer: [*]u8, src_addr: ?*MacAddress, dest_addr: ?*MacAddress, protocol: ?*u16) usize {
        return self._receive(self, header_size, buffer_size, buffer, src_addr, dest_addr, protocol);
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

pub const SimpleNetworkMode = extern struct {
    state: SimpleNetworkState,
    hw_address_size: u32,
    media_header_size: u32,
    max_packet_size: u32,
    nvram_size: u32,
    nvram_access_size: u32,
    receive_filter_mask: u32,
    receive_filter_setting: packed struct {
        receive_unicast: bool,
        receive_multicast: bool,
        receive_broadcast: bool,
        receive_promiscuous: bool,
        receive_promiscuous_multicast: bool,
        _pad: u27,
    },
    max_mcast_filter_count: u32,
    mcast_filter_count: u32,
    mcast_filter: [16]MacAddress,
    current_address: MacAddress,
    broadcast_address: MacAddress,
    permanent_address: MacAddress,
    if_type: u8,
    mac_address_changeable: bool,
    multiple_tx_supported: bool,
    media_present_supported: bool,
    media_present: bool,
};

pub const SimpleNetworkState = extern enum(u32) {
    Stopped,
    Started,
    Initialized,
};

pub const AdapterInformationProtocol = extern struct {
    _get_information: extern fn (*const AdapterInformationProtocol, *align(8) const uefi.Guid, **c_void, *usize) usize,
    _set_information: extern fn (*const AdapterInformationProtocol, *align(8) const uefi.Guid, *const c_void, usize) usize,
    _get_supported_types: extern fn (*const AdapterInformationProtocol, *[*]align(8) uefi.Guid, *usize) usize,

    pub fn getInformation(self: *const AdapterInformationProtocol, information_type: *align(8) const uefi.Guid, information_block: **c_void, information_block_size: *usize) usize {
        return self._get_information(self, information_type, information_block, information_block_size);
    }

    pub fn setInformation(self: *const AdapterInformationProtocol, information_type: *align(8) const uefi.Guid, information_block: *c_void, information_block_size: usize) usize {
        return self._set_information(self, information_type, information_block, information_block_size);
    }

    pub fn getSupportedTypes(self: *const AdapterInformationProtocol, info_types_buffer: *[*]align(8) uefi.Guid, info_types_buffer_count: *usize) usize {
        return self._set_information(self, info_types_buffer, info_types_buffer_count);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0xe5dd1403,
        .time_mid = 0xd622,
        .time_high_and_version = 0xc24e,
        .clock_seq_high_and_reserved = 0x84,
        .clock_seq_low = 0x88,
        .node = [_]u8{ 0xc7, 0x1b, 0x17, 0xf5, 0xe8, 0x02 },
    };
};

pub const AdapterInfoMediaState = extern struct {
    media_state: usize,

    pub const guid align(8) = uefi.Guid{
        .time_low = 0xd7c74207,
        .time_mid = 0xa831,
        .time_high_and_version = 0x4a26,
        .clock_seq_high_and_reserved = 0xb1,
        .clock_seq_low = 0xf5,
        .node = [_]u8{ 0xd1, 0x93, 0x06, 0x5c, 0xe8, 0xb6 },
    };
};

pub const Udp6Protocol = extern struct {
    _get_mode_data: usize, // TODO
    _configure: usize, // TODO
    _groups: usize, // TODO
    _transmit: usize, // TODO
    _receive: usize, // TODO
    _cancel: usize, // TODO
    _poll: usize, // TODO

    pub const guid align(8) = uefi.Guid{
        .time_low = 0x4f948815,
        .time_mid = 0xb4b9,
        .time_high_and_version = 0x43cb,
        .clock_seq_high_and_reserved = 0x8a,
        .clock_seq_low = 0x33,
        .node = [_]u8{ 0x90, 0xe0, 0x60, 0xb3, 0x49, 0x55 },
    };
};

const MacAddress = [32]u8;

pub fn main() void {
    con_out = uefi.system_table.con_out.?;
    const boot_services = uefi.system_table.boot_services.?;

    //_ = con_out.reset(false);

    // We're going to use this buffer to format strings.
    var buf: [1024]u8 = undefined;

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
        var proto: *SimpleNetworkProtocol = undefined;
        const s = boot_services.handleProtocol(handles[i], &SimpleNetworkProtocol.guid, @ptrCast(*?*c_void, &proto));
        if (s == uefi.status.success) {
            printf(buf[0..], "revision = {x}\r\n", proto.revision);
            printf(buf[0..], "mode.state = {x}\r\n", proto.mode.state);
            printf(buf[0..], "start() = {}\r\n", proto.start());
            printf(buf[0..], "stop() = {}\r\n", proto.stop());
            printf(buf[0..], "mode.state = {x}\r\n", proto.mode.state);
            printf(buf[0..], "mode = {}\r\n", proto.mode);
            printf(buf[0..], "mode.state = {x}\r\n", proto.mode.state);
            printf(buf[0..], "mode.current_address = {x}\r\n", proto.mode.current_address);
            printf(buf[0..], "mode.broadcast_address = {x}\r\n", proto.mode.broadcast_address);
            printf(buf[0..], "mode.permanent_address = {x}\r\n", proto.mode.permanent_address);
            printf(buf[0..], "setting receive filters = {}\r\n", proto.receiveFilters(0x2, 0, true, 0, null));
            printf(buf[0..], "initialize() = {}\r\n", proto.initialize(0, 0));
            printf(buf[0..], "setting receive filters = {}\r\n", proto.receiveFilters(0x1, 0, true, 0, null));
            printf(buf[0..], "mode = {}\r\n", proto.mode);
            var header_size: usize = 0;
            var buffer_size: usize = 200;
            var buffer = [_]u8{0} ** 200;
            printf(buf[0..], "sending packet... {}\r\n", proto.transmit(header_size, buffer_size, &buffer, null, null, null));
            var index: usize = undefined;
            _ = boot_services.waitForEvent(1, @ptrCast([*]uefi.Event, &proto.wait_for_packet), &index);
            printf(buf[0..], "receiving packet... {}\r\n", proto.receive(&header_size, &buffer_size, &buffer, null, null, null));
            printf(buf[0..], "stop() = {}\r\n", proto.stop());

            var adapter_info: *AdapterInformationProtocol = undefined;
            const s2 = boot_services.handleProtocol(handles[i], &AdapterInformationProtocol.guid, @ptrCast(*?*c_void, &adapter_info));
            if (s2 == uefi.status.success) {
                var info_block: *c_void = undefined;
                var info_block_size: usize = undefined;
                printf(buf[0..], "getInformation = {}\r\n", adapter_info.getInformation(&AdapterInfoMediaState.guid, &info_block, &info_block_size));
                printf(buf[0..], "{}\r\n", info_block_size);
            } else {
                printf(buf[0..], "handleProtocol() = {}\r\n", s2);
            }
        }
        puts("\r\n");
        _ = boot_services.stall(3 * 1000 * 1000);
    }
    if (status == uefi.status.success) {
        status = boot_services.freePool(@ptrCast(*[*]u8, handles));
        printf(buf[0..], "freePool returned {}\r\n", status);
    }

    puts("\r\n\r\n\r\n");
    printf(buf[0..], "{}\r\n", uefi.status.unsupported);
    _ = boot_services.stall(2 * 1000 * 1000);

    puts("locating handles for udp6...\r\n");
    status = boot_services.locateHandleBuffer(uefi.tables.LocateSearchType.ByProtocol, &Udp6Protocol.guid, null, &no_handles, &handles);
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

    _ = boot_services.stall(100 * 1000 * 1000);
}
