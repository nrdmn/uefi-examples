const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;

var counter: u32 = 0;
var resolution_x: usize = undefined;
var resolution_y: usize = undefined;
var cursor_x: usize = undefined;
var cursor_y: usize = undefined;
var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

fn puts(msg: []const u8) void {
    for (msg) |c| {
        _ = con_out.outputString(&[_]u16{ c, 0 });
    }
}

fn printf(buf: []u8, comptime format: []const u8, args: ...) void {
    puts(fmt.bufPrint(buf, format, args) catch unreachable);
}

extern fn count(event: uefi.Event, context: ?*const c_void) void {
    counter += 1;
    _ = con_out.setCursorPosition(0, 1);
    var buf: [64]u8 = undefined;
    printf(buf[0..], "count() has been called {} times.", counter);
}

pub fn main() void {
    const boot_services = uefi.system_table.boot_services.?;
    con_out = uefi.system_table.con_out.?;
    _ = con_out.reset(false);
    puts("Use the arrow keys to move the cursor.");

    // Get resolution
    _ = con_out.queryMode(con_out.mode.mode, &resolution_x, &resolution_y);
    // Put cursor in the middle
    cursor_x = resolution_x / 2;
    cursor_y = resolution_y / 2;
    _ = con_out.setCursorPosition(cursor_x, cursor_y);
    // Draw cursor
    puts("#");

    var countEvent: uefi.Event = undefined;
    // Create a timer event that runs at priority level 'notify' that calls count() when signalled.
    _ = boot_services.createEvent(uefi.tables.BootServices.event_timer | uefi.tables.BootServices.event_notify_signal, uefi.tables.BootServices.tpl_notify, count, null, &countEvent);
    // Set a timer to signal the event periodically every second.
    _ = boot_services.setTimer(countEvent, uefi.tables.TimerDelay.TimerPeriodic, 1000 * 1000 * 10);

    // Create an array of input events.
    const input_events = [_]uefi.Event{
        uefi.system_table.con_in.?.wait_for_key_ex,
    };
    // TODO add more input events

    var index: usize = undefined;
    // Wait for input events.
    while (boot_services.waitForEvent(input_events.len, &input_events, &index) == uefi.status.success) {
        // index tells us which event has been signalled.

        // Key event
        if (index == 0) {
            var key_data: uefi.protocols.KeyData = undefined;
            if (uefi.system_table.con_in.?.readKeyStrokeEx(&key_data) == uefi.status.success) {
                switch (key_data.key.scan_code) {
                    1 => if (cursor_y > 0) {
                        _ = con_out.setCursorPosition(cursor_x, cursor_y);
                        puts(" ");
                        cursor_y -= 1;
                        _ = con_out.setCursorPosition(cursor_x, cursor_y);
                        puts("#");
                    },
                    2 => if (cursor_y < resolution_y - 1) {
                        _ = con_out.setCursorPosition(cursor_x, cursor_y);
                        puts(" ");
                        cursor_y += 1;
                        _ = con_out.setCursorPosition(cursor_x, cursor_y);
                        puts("#");
                    },
                    3 => if (cursor_x < resolution_x - 1) {
                        _ = con_out.setCursorPosition(cursor_x, cursor_y);
                        puts(" ");
                        cursor_x += 1;
                        _ = con_out.setCursorPosition(cursor_x, cursor_y);
                        puts("#");
                    },
                    4 => if (cursor_x > 0) {
                        _ = con_out.setCursorPosition(cursor_x, cursor_y);
                        puts(" ");
                        cursor_x -= 1;
                        _ = con_out.setCursorPosition(cursor_x, cursor_y);
                        puts("#");
                    },
                    else => {},
                }
            }
        }
    }
}
