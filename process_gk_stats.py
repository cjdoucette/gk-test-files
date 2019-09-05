import sys
import statistics

def npkts_to_mpps(npkts, sec):
    return npkts / float(sec) / 1000. / 1000.

def nbytes_to_gibps(nbytes, sec):
    return nbytes / float(sec) * 8. / 1024. / 1024. / 1024.

if len(sys.argv) != 2:
    sys.exit()

with open(sys.argv[1]) as f:
    total_num_packets = []
    total_num_bytes = []
    cur_num_packets = []
    cur_num_bytes = []
    stats = {}
    for line in f:
       if line.startswith("GATEKEEPER GK: The GK block basic measurements at lcore ="):
           tokens = line.split();
           lcore = tokens[10][:-1]
           n_pkt = int(tokens[13][:-1])
           n_byt = int(tokens[16][:-1])
           if lcore not in stats:
               cur_num_packets.append(n_pkt)
               cur_num_bytes.append(n_byt)
               stats[lcore] = 1
           else:
               total_num_packets.append(sum(cur_num_packets))
               total_num_bytes.append(sum(cur_num_bytes))
               cur_num_packets = []
               cur_num_bytes = []
               stats = {}

# Throw away first and last measurements.
total_num_packets = total_num_packets[1:-1]
total_num_bytes = total_num_bytes[1:-1]
#print("Avg Mpps Avg Gibps")
avg_mpps = npkts_to_mpps(float(sum(total_num_packets)) / len(total_num_packets), 30)
avg_gibps = nbytes_to_gibps(float(sum(total_num_bytes)) / len(total_num_bytes), 30)
print(str(round(avg_mpps, 2)) + "\t " + str(round(avg_gibps, 2)))
#print("Std Mpps Std Gibps")
#std_mpps = npkts_to_mpps(statistics.stdev(total_num_packets), 30)
#std_gibps = nbytes_to_gibps(statistics.stdev(total_num_bytes), 30)
#print(str(round(std_mpps, 2)) + "\t " + str(round(std_gibps, 2)))
