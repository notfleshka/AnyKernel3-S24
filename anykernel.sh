### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Universal Kernel Flasher for Samsung Galaxy S24 series by notfleshka
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=e1s
device.name2=e2s
device.name3=d3s
device.name4=b3s
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/by-name/boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;
NO_MAGISK_CHECK=1

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
split_boot; # Skip ramdisk unpack, since Samsung uses separate init_boot ramdisk

# Optional: Patch DTB or kernel binary here if needed
# e.g., replace_string dtb "orig_value" "new_value" "description";

flash_boot; # Skip repack of ramdisk because it's in init_boot for Samsung 13+

## end boot install


## init_boot files attributes
init_boot_attributes() {
  set_perm_recursive 0 0 755 644 $RAMDISK/*;
  set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# init_boot shell variables
BLOCK=/dev/block/by-name/init_boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# reset for init_boot patching
reset_ak;

# init_boot install
dump_boot; # Unpack ramdisk as it contains the first stage loader

# Example: Patch init scripts or permissions
# backup_file init.rc;
# replace_string init.rc "init_start" "init_custom" "Custom init patch";
# append_file init.rc "custom_init_append" init.s24;

write_boot;
## end init_boot install


## vendor_boot files attributes
vendor_boot_attributes() {
  set_perm_recursive 0 0 755 644 $RAMDISK/*;
  set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# vendor_boot shell variables
BLOCK=/dev/block/by-name/vendor_boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# reset for vendor_boot patching
reset_ak;

# vendor_boot install
dump_boot; # Unpack and repack ramdisk if needed (e.g. custom modules or binaries)

# Optional: Patch fstab or overlay.d entries
# patch_fstab vendor/etc/fstab.gs*.ramdisk /system ext4 options "noatime" "noatime,nodiratime";
# append_file some.rc "custom_vendor_append" vendor_extra;

write_boot;
## end vendor_boot install


## vendor_kernel_boot shell variables
#BLOCK=/dev/block/by-name/vendor_kernel_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for vendor_kernel_boot patching
#reset_ak;

# vendor_kernel_boot install
#split_boot; # No ramdisk, so we skip unpack and repack

#flash_boot;
## end vendor_kernel_boot install