#!/usr/bin/env sh


usage ()
{
    echo "Usage: ${0##*/} mount_dir mount_dir1 mount_to_dir"
    exit 1
}



if [ -z "$1" ]; then
  usage
else
  mount_dir=$1
fi

if [ -z "$2" ]; then
  usage
else
  mount_dir1=$2
fi

if [ -z "$3" ]; then
  usage
else
  mount_to_dir=$3
fi

mkdir "${mount_to_dir}"
mkdir "${mount_dir1}"

echo "Mounting \"${mount_dir}\" to \"${mount_to_dir}\""
mount -t overlay overlay -o lowerdir="${mount_dir}:${mount_dir1}" "${mount_to_dir}"

echo "Waiting for TERM signal . . ."
tail -fn0 $0 & PID=$!
trap "kill $PID" INT TERM

wait

umount  "${mount_to_dir}"

echo "TERM signal is recieved, exit"