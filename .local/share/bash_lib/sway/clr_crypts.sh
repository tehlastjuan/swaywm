#!/usr/bin/env sh
. /usr/local/bin/userenv

# clear empty crypt files
#find /mnt/crypts -empty -type f -exec echo {} \;
# clear empty crypt dirs 
#find /mnt/crypts -empty -type d -exec echo -r {} \;

[ ! -d "$CRYPTS_MOUNT" ] && exit 1

for dir in "$CRYPTS_MOUNT"/*; do
  # clear empty crypt dirs 
  if [ -d "$dir" ]; then
    if [ ! "$(ls -A "$dir")" ]; then
      rm -r "$dir"

      # clear empty crypt files
      file="${dir}.lock"
      if [ -f "$file" ]; then rm "$file"; fi
    fi
  fi
done
