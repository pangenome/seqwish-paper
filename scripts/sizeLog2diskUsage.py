# Usage:
#    cat *.log | python3 scripts/sizeLog2diskUsage.py

import sys

BLOCK_SIZE_BYTES = 1024

file_to_max_size_bytes_dict = {}

for line in sys.stdin:
    if 'total' not in line and '.seqnames.tmp' not in line:
        if len(line.strip().split(' ')) == 2:
            current_size_bytes, file = line.strip().split(' ')

            if 'gfa' in file:
                current_size_bytes = int(current_size_bytes)

                if file not in file_to_max_size_bytes_dict:
                    file_to_max_size_bytes_dict[file] = current_size_bytes
                else:
                    file_to_max_size_bytes_dict[file] = max(file_to_max_size_bytes_dict[file], current_size_bytes)

# Convert the measurements in bytes
for file in file_to_max_size_bytes_dict:
    file_to_max_size_bytes_dict[file] *= BLOCK_SIZE_BYTES

# Debugging: print GFA output files in GBs
#for file, max_size_bytes in file_to_max_size_bytes_dict.items():
#    if file.endswith('.gfa'):
#        print(file, max_size_bytes/1024/1024/1024)

# Sum max sizes for each run
run_to_max_disk_usage_bytes_dict = {}

for file, max_size_bytes in file_to_max_size_bytes_dict.items():
    prefix = file.split('.gfa')[0]

    if prefix not in run_to_max_disk_usage_bytes_dict:
        run_to_max_disk_usage_bytes_dict[prefix] = max_size_bytes
    else:
        run_to_max_disk_usage_bytes_dict[prefix] += max_size_bytes

for run, max_disk_usage_bytes in run_to_max_disk_usage_bytes_dict.items():
    max_disk_usage_str = '{:.4f}'.format(max_disk_usage_bytes/1024/1024/1024)
    print('\t'.join([run, max_disk_usage_str]))
