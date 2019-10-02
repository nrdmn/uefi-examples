const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;

pub fn main() void {
    const boot_services = uefi.system_table.boot_services.?;

    // get graphics protocol
    var graphics: *uefi.protocols.GraphicsOutputProtocol = undefined;
    if (uefi.status.success != boot_services.locateProtocol(&uefi.protocols.GraphicsOutputProtocol.guid, null, @ptrCast(*?*c_void, &graphics))) {
        return;
    }
    var fb: [*]u8 = @intToPtr([*]u8, graphics.mode.frame_buffer_base);

    // get the current memory map
    var memory_map: [*]uefi.tables.MemoryDescriptor = undefined;
    var memory_map_size: usize = 0;
    var memory_map_key: usize = undefined;
    var descriptor_size: usize = undefined;
    var descriptor_version: u32 = undefined;
    while (uefi.status.buffer_too_small == boot_services.getMemoryMap(&memory_map_size, memory_map, &memory_map_key, &descriptor_size, &descriptor_version)) {
        if (uefi.status.success != boot_services.allocatePool(uefi.tables.MemoryType.BootServicesData, memory_map_size, @ptrCast(*[*]u8, &memory_map))) {
            return;
        }
    }

    // Pass the current image's handle and the memory map key to exitBootServices
    // to gain full control over the hardware.
    //
    // exitBootServices may fail. If exitBootServices failed, only getMemoryMap and
    // exitBootservices may be called afterwards. The application may not return
    // anymore after the first call to exitBootServices, even if it was unsuccessful.
    //
    // Most protocols may not be used any more (except for runtime protocols
    // which nobody seems to implement).
    //
    // After exiting boot services, the following fields in the system table should
    // be set to null: ConsoleInHandle, ConIn, ConsoleOutHandle, ConOut,
    // StandardErrorHandle, StdErr, and BootServicesTable. Because the fields are
    // being modified, the table's CRC32 must be recomputed.
    //
    // All events of type event_signal_exit_boot_services will be signaled.
    //
    // Runtime services may be used. However, some restrictions apply. See the
    // UEFI specification for more information.
    if (uefi.status.success == boot_services.exitBootServices(uefi.handle, memory_map_key)) {
        // We may still use the frame buffer!

        // draw some colors
        var i: u32 = 0;
        while (i < 640*480*4) : (i += 4) {
            fb[i] = @truncate(u8, @divTrunc(i, 256));
            fb[i+1] = @truncate(u8, @divTrunc(i, 1536));
            fb[i+2] = @truncate(u8, @divTrunc(i, 2560));
        }
    }

    while (true) {}
}
