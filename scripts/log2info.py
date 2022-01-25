# Usage:
#    cat *.log | python3 scripts/log2info.py

import sys

input_fasta = ''
input_paf = ''
gfa_name = ''
s = ''
l = ''
p = ''
n = ''
k = ''
B = ''
elapsed_wall_clock_time = ''
max_resident_set_size = ''

reject_result = False

for line in sys.stdin:
    if 'Command terminated by signal' in line:
        reject_result = True
    elif 'Command being timed' in line:
        gfa_name = line.split('.gfa')[0].split('/')[-1]

        input_fasta = line.split('-s ')[1].split('.fasta.gz')[0].split('/')[-1]
        input_paf = line.split('-p ')[1].split('.paf.gz')[0].split('/')[-1]

        if len(gfa_name.split('.')) == 7:
            # Remove the parameter name (single character) from each string
            s, l, p, n, k, B = [x[1:] for x in gfa_name.split('.')[1:]]

        elapsed_wall_clock_time = ''
        max_resident_set_size = ''
    elif 'Elapsed (wall clock) time' in line:
        elapsed_wall_clock_time = line.strip().split('): ')[-1]

        max_resident_set_size = ''
    elif 'Maximum resident set size' in line:
        max_resident_set_size = line.strip().split('): ')[-1]

        # Convert in Gbytes
        max_resident_set_size = '{:.4f}'.format(float(max_resident_set_size)/1024/1024)

        # Check if all information are available
        if not reject_result and input_fasta and input_paf and gfa_name and input and s and l and p and n and k and B and elapsed_wall_clock_time and max_resident_set_size:
            print('\t'.join([gfa_name, input_fasta, input_paf, s, l, p, n, k, B, elapsed_wall_clock_time, max_resident_set_size]))

        input_fasta = ''
        input_paf = ''
        gfa_name = ''
        s = ''
        l = ''
        p = ''
        n = ''
        k = ''
        B = ''
        elapsed_wall_clock_time = ''
        max_resident_set_size = ''

        reject_result = False
