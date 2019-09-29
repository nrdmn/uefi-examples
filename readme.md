# UEFI examples in Zig
This repo contains examples about how to use Zig to build UEFI apps.

Recommended reading order:
1. hello
1. protocols
1. events (TODO)
1. memory (TODO)
1. efivars (TODO)
1. hii (TODO)

## How to build and run.
Run `zig build` in any of the subdirectories to build.
Then you can copy the output file to a FAT32 formatted device to `efi/boot/bootx64.efi`.
Alternatively you can use QEMU with `qemu-system-x86_64 -bios /usr/share/edk2-ovmf/OVMF_CODE.fd -hdd fat:rw:. -serial stdio`.

## FAQ
### How much stack space do I get?
At least 128 KiB before calling `exitBootServices()`.
After calling `exitBootServices()` you have to provide at least 4 KiB.

### Why does my computer reboot after 5 minutes?
By default, your firmware's watchdog reboots your system after 5 minutes if your application does not call `exitBootServices()`.
You can disable the watchdog timer using `boot_services.setWatchdogTimer(0, 0, 0, null)`.

### Where do I get more information?
Read the spec.
It's really well written.

## Further reading
- https://uefi.org/sites/default/files/resources/UEFI_Spec_2_8_final.pdf
- https://www.intel.com/content/dam/doc/guide/efi-driver-writers-v1-10-guide.pdf
