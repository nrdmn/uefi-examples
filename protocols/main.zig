const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;

// Assigned in main().
var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

// We need to print each character in an [_]u8 individually because EFI
// encodes strings as UCS-2.
fn puts(msg: []const u8) void {
    for (msg) |c| {
        _ = con_out.outputString(&[_:0]u16{c});
    }
}

fn printf(buf: []u8, comptime format: []const u8, args: var) void {
    puts(fmt.bufPrint(buf, format, args) catch unreachable);
}

pub fn main() void {
    con_out = uefi.system_table.con_out.?;
    const boot_services = uefi.system_table.boot_services.?;

    _ = con_out.reset(false);

    // We're going to use this buffer to format strings.
    var buf: [100]u8 = undefined;

    // Let's find some protocols that our environment provides to us.

    // con_out is a *SimpleTextOutputProtocol, but for the sake of this example,
    // let's find it using locateProtocol(). All protocols have a unique GUID by
    // which we can find them. locateProtocol() returns the first matching protocol.
    var simple_text_output_protocol: ?*uefi.protocols.SimpleTextOutputProtocol = undefined;
    if (boot_services.locateProtocol(&uefi.protocols.SimpleTextOutputProtocol.guid, null, @ptrCast(*?*c_void, &simple_text_output_protocol)) == uefi.status.success) {
        puts("*** simple text output protocol is supported!\r\n");

        // simple_text_output_protocol is only null if no protocol has been found.
        // The output device may support multiple resolutions. Let's list them:
        var i: u32 = 0;
        while (i < simple_text_output_protocol.?.mode.max_mode) : (i += 1) {
            var x: usize = undefined;
            var y: usize = undefined;
            // queryMode can fail on device error or if we request an invalid mode.
            _ = simple_text_output_protocol.?.queryMode(i, &x, &y);
            printf(buf[0..], "    mode {} = {}x{}\r\n", .{ i, x, y });
        }
    } else {
        puts("*** simple text output protocol is NOT supported :(\r\n");
    }
    _ = boot_services.stall(3 * 1000 * 1000);

    // Do we have a relative pointing device (mouse, touchpad)?
    // NOTE: Many firmwares, including OVMF, locate a protocol here even if
    // they don't support mice or touchscreens.
    var simple_pointer_protocol: ?*uefi.protocols.SimplePointerProtocol = undefined;
    if (boot_services.locateProtocol(&uefi.protocols.SimplePointerProtocol.guid, null, @ptrCast(*?*c_void, &simple_pointer_protocol)) == uefi.status.success) {
        puts("*** simple pointer protocol is supported!\r\n");

        // Check the device's resolution:
        printf(buf[0..], "    resolution x = {} per mm\r\n", .{simple_pointer_protocol.?.mode.resolution_x});
        printf(buf[0..], "    resolution y = {} per mm\r\n", .{simple_pointer_protocol.?.mode.resolution_y});
        printf(buf[0..], "    resolution z = {} per mm\r\n", .{simple_pointer_protocol.?.mode.resolution_z});

        // Does it have buttons?
        if (simple_pointer_protocol.?.mode.left_button) {
            puts("    has left button\r\n");
        } else {
            puts("    doesn't have left button\r\n");
        }
        if (simple_pointer_protocol.?.mode.right_button) {
            puts("    has right button\r\n");
        } else {
            puts("    doesn't have right button\r\n");
        }
    } else {
        puts("*** simple pointer protocol is NOT supported :(\r\n");
    }
    _ = boot_services.stall(3 * 1000 * 1000);

    // Do we have an absolute pointing device (touchscreen)?
    // NOTE: see note above.
    var absolute_pointer_protocol: ?*uefi.protocols.AbsolutePointerProtocol = undefined;
    if (boot_services.locateProtocol(&uefi.protocols.AbsolutePointerProtocol.guid, null, @ptrCast(*?*c_void, &absolute_pointer_protocol)) == uefi.status.success) {
        puts("*** absolute pointer protocol is supported!\r\n");

        // Check the device's resolution:
        printf(buf[0..], "    absolute min x = {}\r\n", .{absolute_pointer_protocol.?.mode.absolute_min_x});
        printf(buf[0..], "    absolute min y = {}\r\n", .{absolute_pointer_protocol.?.mode.absolute_min_y});
        printf(buf[0..], "    absolute min z = {}\r\n", .{absolute_pointer_protocol.?.mode.absolute_min_z});
        printf(buf[0..], "    absolute max x = {}\r\n", .{absolute_pointer_protocol.?.mode.absolute_max_x});
        printf(buf[0..], "    absolute max y = {}\r\n", .{absolute_pointer_protocol.?.mode.absolute_max_y});
        printf(buf[0..], "    absolute max z = {}\r\n", .{absolute_pointer_protocol.?.mode.absolute_max_z});

        if (absolute_pointer_protocol.?.mode.attributes.supports_alt_active) {
            puts("    supports alt active\r\n");
        } else {
            puts("    doesn't support alt active\r\n");
        }
        if (absolute_pointer_protocol.?.mode.attributes.supports_pressure_as_z) {
            puts("    supports pressure as z\r\n");
        } else {
            puts("    doesn't support pressure as z\r\n");
        }
    } else {
        puts("*** absolute pointer protocol is NOT supported :(\r\n");
    }
    _ = boot_services.stall(3 * 1000 * 1000);

    // Graphics output?
    var graphics_output_protocol: ?*uefi.protocols.GraphicsOutputProtocol = undefined;
    if (boot_services.locateProtocol(&uefi.protocols.GraphicsOutputProtocol.guid, null, @ptrCast(*?*c_void, &graphics_output_protocol)) == 0) {
        puts("*** graphics output protocol is supported!\r\n");

        // Check supported resolutions:
        var i: u32 = 0;
        while (i < graphics_output_protocol.?.mode.max_mode) : (i += 1) {
            var info: *uefi.protocols.GraphicsOutputModeInformation = undefined;
            var info_size: usize = undefined;
            _ = graphics_output_protocol.?.queryMode(i, &info_size, &info);
            printf(buf[0..], "    mode {} = {}x{}\r\n", .{ i, info.horizontal_resolution, info.vertical_resolution });
        }

        printf(buf[0..], "    current mode = {}\r\n", .{graphics_output_protocol.?.mode.mode});
    } else {
        puts("*** graphics output protocol is NOT supported :(\r\n");
    }
    _ = boot_services.stall(3 * 1000 * 1000);

    // What about a random number generator?
    var rng_protocol: ?*uefi.protocols.RNGProtocol = undefined;
    if (boot_services.locateProtocol(&uefi.protocols.RNGProtocol.guid, null, @ptrCast(*?*c_void, &rng_protocol)) == uefi.status.success) {
        puts("*** rng protocol is supported!\r\n");

        // We can pick a rng, but we're going to use the default one.
        var lucky_number: u8 = undefined;
        var status = rng_protocol.?.getRNG(null, 1, @ptrCast([*]u8, &lucky_number));
        if (status == uefi.status.success) {
            printf(buf[0..], "    your lucky number = {}\r\n", .{lucky_number});
        } else {
            // Generating random numbers can fail.
            printf(buf[0..], "    no luck today, reason = {}\r\n", .{switch (status) {
                uefi.status.unsupported => "unsupported"[0..],
                uefi.status.device_error => "device error"[0..],
                uefi.status.not_ready => "not ready"[0..],
                uefi.status.invalid_parameter => "invalid parameter"[0..],
                else => "(unknown)"[0..],
            }});
        }
    } else {
        puts("*** rng protocol is NOT supported :(\r\n");
    }
    _ = boot_services.stall(3 * 1000 * 1000);
}
