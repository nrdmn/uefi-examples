const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;

// Assigned in main().
var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

fn puts(msg: []const u8) void {
    for (msg) |c| {
        const c_ = [2]u16{ c, 0 }; // work around https://github.com/ziglang/zig/issues/4372
        _ = con_out.outputString(@ptrCast(*const [1:0]u16, &c_));
    }
}

fn printf(buf: []u8, comptime format: []const u8, args: var) void {
    puts(fmt.bufPrint(buf, format, args) catch unreachable);
}

fn cmpGuid(a: uefi.Guid, b: uefi.Guid) bool {
    return @bitCast(u128, a) == @bitCast(u128, b);
}

fn guidname(a: uefi.Guid) ?[]const u8 {
    const guids = [_]struct { @"0": *const uefi.Guid, @"1": []const u8 }{
        .{ .@"0" = &uefi.tables.ConfigurationTable.acpi_10_table_guid, .@"1" = "ACPI_TABLE_GUID" },
        .{ .@"0" = &uefi.protocols.AbsolutePointerProtocol.guid, .@"1" = "EFI_ABSOLUTE_POINTER_PROTOCOL" },
        .{ .@"0" = &uefi.tables.ConfigurationTable.acpi_20_table_guid, .@"1" = "EFI_ACPI_TABLE_GUID" },
        .{ .@"0" = &uefi.protocols.DevicePathProtocol.guid, .@"1" = "EFI_DEVICE_PATH_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.EdidActiveProtocol.guid, .@"1" = "EFI_EDID_ACTIVE_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.EdidDiscoveredProtocol.guid, .@"1" = "EFI_EDID_DISCOVERED_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.EdidOverrideProtocol.guid, .@"1" = "EFI_EDID_OVERRIDE_PROTOCOL" },
        .{ .@"0" = &uefi.tables.global_variable, .@"1" = "EFI_GLOBAL_VARIABLE" },
        .{ .@"0" = &uefi.protocols.GraphicsOutputProtocol.guid, .@"1" = "EFI_GRAPHICS_OUTPUT_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.HIIDatabaseProtocol.guid, .@"1" = "EFI_HII_DATABASE_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.HIIPopupProtocol.guid, .@"1" = "EFI_HII_POPUP_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.Ip6ConfigProtocol.guid, .@"1" = "EFI_IP6_CONFIG_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.Ip6Protocol.guid, .@"1" = "EFI_IP6_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.Ip6ServiceBindingProtocol.guid, .@"1" = "EFI_IP6_SERVICE_BINDING_PROTOCOL" },
        .{ .@"0" = &uefi.tables.ConfigurationTable.json_capsule_data_table_guid, .@"1" = "JSON_CAPSULE_DATA_TABLE_GUID" },
        .{ .@"0" = &uefi.tables.ConfigurationTable.json_capsule_result_table_guid, .@"1" = "JSON_CAPSULE_RESULT_TABLE_GUID" },
        .{ .@"0" = &uefi.tables.ConfigurationTable.json_config_data_table_guid, .@"1" = "JSON_CONFIG_DATA_TABLE_GUID" },
        .{ .@"0" = &uefi.protocols.LoadedImageProtocol.guid, .@"1" = "EFI_LOADED_IMAGE_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.loaded_image_device_path_protocol_guid, .@"1" = "EFI_LOADED_IMAGE_DEVICE_PATH_PROTOCOL_GUID" },
        .{ .@"0" = &uefi.protocols.ManagedNetworkProtocol.guid, .@"1" = "EFI_MANAGED_NETWORK_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.ManagedNetworkServiceBindingProtocol.guid, .@"1" = "EFI_MANAGED_NETWORK_SERVICE_BINDING_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.RNGProtocol.guid, .@"1" = "EFI_RNG_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.ShellParametersProtocol.guid, .@"1" = "EFI_SHELL_PARAMETERS_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.SimpleNetworkProtocol.guid, .@"1" = "EFI_SIMPLE_NETWORK_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.SimplePointerProtocol.guid, .@"1" = "EFI_SIMPLE_POINTER_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.SimpleTextInputExProtocol.guid, .@"1" = "EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.SimpleTextInputProtocol.guid, .@"1" = "EFI_SIMPLE_TEXT_INPUT_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.SimpleTextOutputProtocol.guid, .@"1" = "EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.Udp6Protocol.guid, .@"1" = "EFI_UDP6_PROTOCOL" },
        .{ .@"0" = &uefi.protocols.Udp6ServiceBindingProtocol.guid, .@"1" = "EFI_UDP6_SERVICE_BINDING_PROTOCOL" },
        .{ .@"0" = &uefi.tables.ConfigurationTable.mps_table_guid, .@"1" = "MPS_TABLE_GUID" },
        .{ .@"0" = &uefi.tables.ConfigurationTable.sal_system_table_guid, .@"1" = "SAL_SYSTEM_TABLE_GUID" },
        .{ .@"0" = &uefi.tables.ConfigurationTable.smbios_table_guid, .@"1" = "SMBIOS_TABLE_GUID" },
        .{ .@"0" = &uefi.tables.ConfigurationTable.smbios3_table_guid, .@"1" = "SMBIOS3_TABLE_GUID" },
    };
    for (guids) |b| {
        if (cmpGuid(a, b.@"0".*)) {
            return b.@"1";
        }
    }
    return null;
}

pub fn main() void {
    con_out = uefi.system_table.con_out.?;
    const boot_services = uefi.system_table.boot_services.?;

    _ = con_out.reset(false);

    var buf: [256]u8 = undefined;

    var handles: []uefi.Handle = undefined;
    _ = boot_services.locateHandleBuffer(uefi.tables.LocateSearchType.AllHandles, null, null, &handles.len, &handles.ptr);
    for (handles) |handle| {
        puts("\r\n********************************************************\r\n\r\n");
        var supports_loaded_image_protocol = false;
        var supports_shell_parameters_protocol = false;
        printf(buf[0..], "{}\r\n\r\n", .{handle});

        puts("It supports the following protocols\r\n");
        var protocols: []*align(8) uefi.Guid = undefined;
        _ = boot_services.protocolsPerHandle(handle, &protocols.ptr, &protocols.len);
        for (protocols) |guid| {
            printf(buf[0..], "{} {}\r\n", .{ guid, guidname(guid.*) });
            supports_loaded_image_protocol = supports_loaded_image_protocol or cmpGuid(guid.*, uefi.protocols.LoadedImageProtocol.guid);
            supports_shell_parameters_protocol = supports_shell_parameters_protocol or cmpGuid(guid.*, uefi.protocols.ShellParametersProtocol.guid);
        }
        _ = boot_services.freePool(@ptrCast([*]u8, protocols.ptr));

        if (supports_loaded_image_protocol) {
            puts("\r\nThe handle is of an image, so here's some info about the image:\r\n");
            var loaded_image_protocol: *uefi.protocols.LoadedImageProtocol = undefined;
            _ = boot_services.openProtocol(handle, &uefi.protocols.LoadedImageProtocol.guid, @ptrCast(*?*c_void, &loaded_image_protocol), uefi.handle, null, .{ .get_protocol = true });
            printf(buf[0..], "revision = {}\r\n", .{loaded_image_protocol.revision});
            printf(buf[0..], "parent_handle = {}\r\n", .{loaded_image_protocol.parent_handle});
            printf(buf[0..], "system_table = {*}\r\n", .{loaded_image_protocol.system_table});
            printf(buf[0..], "device_handle = {}\r\n", .{loaded_image_protocol.device_handle});
            printf(buf[0..], "file_path = {}\r\n", .{loaded_image_protocol.file_path.getDevicePath()});
            if (loaded_image_protocol.file_path.getDevicePath()) |device_path| {
                switch (device_path) {
                    .Media => |media_device_path| switch (media_device_path) {
                        .FilePath => |file_path_device_path| {
                            puts("  path = ");
                            _ = con_out.outputString(file_path_device_path.*.getPath());
                            puts("\r\n");
                        },
                        else => {},
                    },
                    else => {},
                }
            }
            //printf(buf[0..], "file_path = {}\r\n", .{loaded_image_protocol.file_path});
            printf(buf[0..], "(reserved) = {}\r\n", .{loaded_image_protocol.reserved});
            printf(buf[0..], "load_options_size = {}\r\n", .{loaded_image_protocol.load_options_size});
            if (loaded_image_protocol.load_options != null) {
                const load_options = @ptrCast([*]u8, loaded_image_protocol.load_options)[0..loaded_image_protocol.load_options_size];
                printf(buf[0..], "load_options = {x}\r\n", .{load_options});
            } else {
                puts("load_options = null\r\n");
            }
            printf(buf[0..], "image_base = {*}\r\n", .{loaded_image_protocol.image_base});
            printf(buf[0..], "image_size = {}\r\n", .{loaded_image_protocol.image_size});
            printf(buf[0..], "image_code_type = {}\r\n", .{loaded_image_protocol.image_code_type});
            printf(buf[0..], "image_data_type = {}\r\n", .{loaded_image_protocol.image_data_type});
            _ = boot_services.closeProtocol(handle, &uefi.protocols.LoadedImageProtocol.guid, uefi.handle, null);
        }

        if (supports_shell_parameters_protocol) {
            var shell_parameters_protocol: *uefi.protocols.ShellParametersProtocol = undefined;
            _ = boot_services.openProtocol(handle, &uefi.protocols.ShellParametersProtocol.guid, @ptrCast(*?*c_void, &shell_parameters_protocol), uefi.handle, null, .{ .get_protocol = true });
            printf(buf[0..], "\r\nThe handle has {} shell parameters:\r\n", .{shell_parameters_protocol.argc});
            const params = shell_parameters_protocol.argv[0..shell_parameters_protocol.argc];
            for (params) |param| {
                _ = con_out.outputString(param);
                puts("\r\n");
            }
            _ = boot_services.closeProtocol(handle, &uefi.protocols.ShellParametersProtocol.guid, uefi.handle, null);
        }
    }
    _ = boot_services.freePool(@ptrCast([*]u8, handles.ptr));

    _ = boot_services.stall(20 * 1000 * 1000);
}
