#!/usr/bin/env bash

MOUNTED_DEVS=''

$ECHO mkdir -p ${PREMOUNT_MBR_OUTPUT_DIR}
cd ${PREMOUNT_MBR_OUTPUT_DIR}

for mountpoint in ${SRC_DIRECTORIES}; do
    MOUNTED_DEVS+=" `findmnt "${mountpoint}" -euUn | tr -s ' ' | cut -d ' ' -f2`"
done

DISKS=`echo $MOUNTED_DEVS | sed 's/[0-9]//g' | sort | uniq`

DATE="$(full_date)"

for disk in $DISKS; do
    disk_ident_str="`lsblk --output name,model,serial -nd $disk | tr -s ' ' | sed 's/ /_/g'`"
    bin_name="mbr.${disk_ident_str}.${DATE}.bin"

    [[ $VERBOSE -ne 0 ]] && echo "* dumping ${disk} MBR to  ${bin_name}"
    $ECHO dd if=${disk} of=${bin_name} bs=512 count=1
done

for i in `find . -name '*.bin' -type f -mtime +${PREMOUNT_MBR_DELETE_FILES_OLDER_THAN} | sort`; do
    $ECHO rm $i
    [[ $VERBOSE -ne 0 ]] && echo "* removed $i"
done

exit 0
