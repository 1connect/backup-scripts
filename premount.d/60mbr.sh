#!/usr/bin/env bash

$ECHO mkdir -p ${PREMOUNT_MBR_OUTPUT_DIR}
cd ${PREMOUNT_MBR_OUTPUT_DIR}

DATE="$(full_date)"

for disk in ${PREMOUNT_MBR_PHYSICAL_DEVICES}; do
    disk_ident_str="`lsblk --output name,model,serial -nd $disk | tr -s ' ' | sed 's/ /_/g'`"
    bin_name="mbr.${disk_ident_str}.${DATE}.bin"

    [[ $VERBOSE -ne 0 ]] && echo "* dumping ${disk} MBR to  ${bin_name}"
    $ECHO dd if=${disk} of=${bin_name} bs=512 count=1 &> /dev/null
    $ECHO chmod 0400 ${bin_name}
done

for i in `find . -name '*.bin' -type f -mtime +${PREMOUNT_MBR_DELETE_FILES_OLDER_THAN} | sort`; do
    $ECHO rm $i
    [[ $VERBOSE -ne 0 ]] && echo "* removed $i"
done

exit 0
