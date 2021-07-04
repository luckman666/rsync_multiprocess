#!/usr/bin/env bash
 
# Define source, target, maxdepth and cd to source
source="/tmp/tmp_data"
target="/tmp/tmp_data2"
depth=3
cd "${source}"
 
# Set the maximum number of concurrent rsync threads
maxthreads=5
# How long to wait before checking the number of rsync threads again
sleeptime=5
 
# Find all folders in the source directory within the maxdepth level
find . -maxdepth ${depth} -type d | while read dir
do
       # Make sure to ignore the parent folder
       if [ `echo "${dir}" | awk -F'/' '{print NF}'` -gt ${depth} ]
       then
           # Strip leading dot slash
           subfolder=$(echo "${dir}" | sed 's@^\./@@g')
           if [ ! -d "${target}/${subfolder}" ]
           then
               # Create destination folder
               mkdir -p "${target}/${subfolder}"
           fi
           # Make sure the number of rsync threads running is below the threshold
           while [ `ps -ef | grep -w [r]sync | awk '{print $NF}' | sort -nr | uniq | wc -l` -ge ${maxthreads} ]
           do
               echo "Sleeping ${sleeptime} seconds"
               sleep ${sleeptime}
           done
           # Run rsync in background for the current subfolder and move one to the next one
           nohup rsync -avP "${source}/${subfolder}/" "${target}/${subfolder}/" </dev/null >/dev/null 2>&1 &
       fi
done
 
# Find all files above the maxdepth level and rsync them as well
find . -maxdepth ${depth} -type f -print0 | rsync -avP --files-from=- --from0 ./ "${target}/"
