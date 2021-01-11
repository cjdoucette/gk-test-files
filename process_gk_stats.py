import sys
import statistics
import numpy

def npkts_to_mpps(npkts, sec):
    return npkts / float(sec) / 1000. / 1000.

def nbytes_to_gibps(nbytes, sec):
    return nbytes / float(sec) * 8. / 1024. / 1024. / 1024.

if len(sys.argv) != 3:
    sys.exit()

#
# Process GK block measurements.
#

# Totals of packets and bytes for each measurement, i.e. index 0
# holds the total packets and bytes processed across all lcores at
# the first measurement, etc.
gk_total_num_packets = []
gk_total_num_bytes = []

with open(sys.argv[1]) as f:
    # Number of packets and bytes for measurement currently being
    # inspected. We need a list because when there are multiple
    # lcores, the measurements are output by Gatekeeper on separate
    # lines, per-lcore.
    cur_num_packets = []
    cur_num_bytes = []
    stats = {}
    for line in f:
       if line.startswith("GATEKEEPER GK: The GK block basic measurements at lcore ="):
           tokens = line.split();
           lcore = tokens[10][:-1]
           n_pkt = int(tokens[13][:-1])
           n_byt = int(tokens[16][:-1])
           if lcore in stats:
               # We have collected stats for all lcores for this measurement.
               gk_total_num_packets.append(sum(cur_num_packets))
               gk_total_num_bytes.append(sum(cur_num_bytes))
               cur_num_packets = []
               cur_num_bytes = []
               stats = {}
           cur_num_packets.append(n_pkt)
           cur_num_bytes.append(n_byt)
           stats[lcore] = 1

    if len(cur_num_packets) > 0:
        gk_total_num_packets.append(sum(cur_num_packets))
        gk_total_num_bytes.append(sum(cur_num_bytes))

# Throw away the first measurement.
gk_total_num_packets = gk_total_num_packets[1:]
gk_total_num_bytes = gk_total_num_bytes[1:]

#
# Process client measurements.
#

# Totals of packets and bytes for each measurement, i.e. index 0
# holds the total packets and bytes sent at the first measurement, etc.
cli_total_num_packets = []
cli_total_num_bytes = []

with open(sys.argv[2]) as f:
    first = True
    prev_pkt = None
    prev_byt = None
    for line in f:
        if line.startswith("        TX packets"):
            tokens = line.split();
            n_pkt = int(tokens[2])
            n_byt = int(tokens[4])
            if first:
                prev_pkt = n_pkt
                prev_byt = n_byt
                first = False
                continue
            cli_total_num_packets.append(n_pkt - prev_pkt)
            cli_total_num_bytes.append(n_byt - prev_byt)
            prev_pkt = n_pkt
            prev_byt = n_byt

# Note: currently only outputting packet measurements, not bytes.
gk_mpps_0 = round(npkts_to_mpps(numpy.percentile(gk_total_num_packets, 0), 60), 2)
gk_mpps_50 = round(npkts_to_mpps(numpy.percentile(gk_total_num_packets, 50), 60), 2)
gk_mpps_99 = round(npkts_to_mpps(numpy.percentile(gk_total_num_packets, 99), 60), 2)
gk_mpps_mean = round(npkts_to_mpps(float(sum(gk_total_num_packets)) / len(gk_total_num_packets), 60), 2)

#print(cli_total_num_packets)
cli_mpps_0 = round(npkts_to_mpps(numpy.percentile(cli_total_num_packets, 0), 1), 2)
cli_mpps_50 = round(npkts_to_mpps(numpy.percentile(cli_total_num_packets, 50), 1), 2)
cli_mpps_99 = round(npkts_to_mpps(numpy.percentile(cli_total_num_packets, 99), 1), 2)
cli_mpps_mean = round(npkts_to_mpps(float(sum(cli_total_num_packets)) / len(cli_total_num_packets), 1), 2)

print(str(gk_mpps_0) + "\t" +
    str(gk_mpps_50) + "\t" +
    str(gk_mpps_99) + "\t" +
    str(gk_mpps_mean) + "\t" +
    str(cli_mpps_0) + "\t" +
    str(cli_mpps_50) + "\t" +
    str(cli_mpps_99) + "\t" +
    str(cli_mpps_mean))
