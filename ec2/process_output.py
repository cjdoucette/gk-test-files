import sys

exp_name = sys.argv[1]
rates = ['100mbps', '500mbps', '1gbps', '2gbps', '3gbps', '4gbps',
        '5gbps', '6gbps', '7gbps', '8gbps']

for rate in rates:
    filename = 'results/' + exp_name + '/' + rate + '/output.txt'
    with open(filename) as f:
        lines = []
        for line in f:
            lines.append(line)

        flood_rate = lines[5].split(sep='\t')[3].strip()
        completed_conns = lines[-2].split()[1]
        legit_transfer_time = lines[-1].split(sep='\t')[3].strip()

        print(flood_rate + '\t' + legit_transfer_time + '\t' + completed_conns)
