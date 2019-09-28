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

## Further reading
- https://uefi.org/sites/default/files/resources/UEFI_Spec_2_8_final.pdf
- https://www.intel.com/content/dam/doc/guide/efi-driver-writers-v1-10-guide.pdf
