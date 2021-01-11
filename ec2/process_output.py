import sys

exp_name = sys.argv[1]
if len(sys.argv) == 3:
    other_params = sys.argv[2]
else:
    other_params = None
rates = ['100mibps', '500mibps', '1gibps', '2gibps', '3gibps', '4gibps',
    '5gibps', '6gibps', '7gibps', '8gibps']

for rate in rates:
    if other_params is not None:
        filename = 'results/' + exp_name + '/' + rate + '_' + other_params + '/output.txt'
    else:
        filename = 'results/' + exp_name + '/' + rate + '/output.txt'
    with open(filename) as f:
        lines = []
        for line in f:
            lines.append(line)

        flood_rate = lines[8].split(sep='\t')[3].strip()
        completed_conns = lines[-2].split()[1]
        legit_transfer_time = lines[-1].split(sep='\t')[3].strip()

        print(flood_rate + '\t' + legit_transfer_time + '\t' + completed_conns)
