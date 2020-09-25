import sys
import statistics
import numpy

def npkts_to_mpps(npkts, sec):
    return npkts / float(sec) / 1000. / 1000.

def npkts_to_kpps(npkts, sec):
    return npkts / float(sec) / 1000.

def nbytes_to_gibps(nbytes, sec):
    return nbytes / float(sec) * 8. / 1024. / 1024. / 1024.

def nbytes_to_mibps(nbytes, sec):
    return nbytes / float(sec) * 8. / 1024. / 1024.

if len(sys.argv) != 4 and len(sys.argv) != 2:
    print("Need filenames for the Gatekeeper log and/or the server output log")
    sys.exit()

if len(sys.argv) == 4:
    gk_log = sys.argv[1]
    client_log = sys.argv[2];
    server_log = sys.argv[3];
elif len(sys.argv) == 2:
    server = ['server_ifconfig', '.txt', 'server', 'dest']
    server_log = None
    for s in server:
        if s in sys.argv[1]:
            print("Guessing " + sys.argv[1] + " is for the server output log")
            server_log = sys.argv[1]
            gk_log = None
    if server_log is None:
        print("Guessing " + sys.argv[1] + " is for the Gatekeeper log")
        gk_log = sys.argv[1]

#
# Process GK block measurements.
#

# Totals of packets and bytes for each measurement, i.e. index 0
# holds the total packets and bytes processed across all lcores at
# the first measurement, etc.
gk_total_num_packets = []
gk_total_num_bytes = []

if gk_log is not None:
    with open(gk_log) as f:
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
                   gk_total_num_packets.append(sum(cur_num_packets))
                   gk_total_num_bytes.append(sum(cur_num_bytes))
                   stats = {}
                   cur_num_packets = []
                   cur_num_bytes = []
               cur_num_packets.append(n_pkt)
               cur_num_bytes.append(n_byt)
               stats[lcore] = 1

        if len(cur_num_packets) > 0:
            gk_total_num_packets.append(sum(cur_num_packets))
            gk_total_num_bytes.append(sum(cur_num_bytes))

    # Note: currently only outputting packet measurements, not bytes.
    print("Gatekeeper measurements:")
    print(gk_total_num_bytes)
    gk_mpps_0 = round(npkts_to_mpps(numpy.percentile(gk_total_num_packets, 0), 30), 2)
    gk_mpps_50 = round(npkts_to_mpps(numpy.percentile(gk_total_num_packets, 50), 30), 2)
    gk_mpps_99 = round(npkts_to_mpps(numpy.percentile(gk_total_num_packets, 99), 30), 2)
    gk_mpps_mean = round(npkts_to_mpps(float(sum(gk_total_num_packets)) / len(gk_total_num_packets), 30), 2)

    if gk_mpps_99 < .01:
        gk_mpps_0 = round(npkts_to_kpps(numpy.percentile(gk_total_num_packets, 0), 30), 2)
        gk_mpps_50 = round(npkts_to_kpps(numpy.percentile(gk_total_num_packets, 50), 30), 2)
        gk_mpps_99 = round(npkts_to_kpps(numpy.percentile(gk_total_num_packets, 99), 30), 2)
        gk_mpps_mean = round(npkts_to_kpps(float(sum(gk_total_num_packets)) / len(gk_total_num_packets), 30), 2)

#
# Process server/client measurements.
#

cli_total_num_packets = []
cli_total_num_bytes = []

if client_log is not None:
    with open(client_log) as f:
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

    print("Client measurements:")
    cli_total_num_packets = cli_total_num_packets[3:-3]
    cli_total_num_bytes = cli_total_num_bytes[3:-3]
    print(cli_total_num_bytes)
    cli_mpps_0 = round(npkts_to_mpps(numpy.percentile(cli_total_num_packets, 0), 1), 2)
    cli_mpps_50 = round(npkts_to_mpps(numpy.percentile(cli_total_num_packets, 50), 1), 2)
    cli_mpps_99 = round(npkts_to_mpps(numpy.percentile(cli_total_num_packets, 99), 1), 2)
    cli_mpps_mean = round(npkts_to_mpps(float(sum(cli_total_num_packets)) / len(cli_total_num_packets), 1), 2)

    if cli_mpps_99 < .01:
        cli_mpps_0 = round(npkts_to_kpps(numpy.percentile(cli_total_num_packets, 0), 1), 2)
        cli_mpps_50 = round(npkts_to_kpps(numpy.percentile(cli_total_num_packets, 50), 1), 2)
        cli_mpps_99 = round(npkts_to_kpps(numpy.percentile(cli_total_num_packets, 99), 1), 2)
        cli_mpps_mean = round(npkts_to_kpps(float(sum(cli_total_num_packets)) / len(cli_total_num_packets), 1), 2)

    cli_mbps_0 = round(nbytes_to_mibps(numpy.percentile(cli_total_num_bytes, 0), 1), 2)
    cli_mbps_50 = round(nbytes_to_mibps(numpy.percentile(cli_total_num_bytes, 50), 1), 2)
    cli_mbps_99 = round(nbytes_to_mibps(numpy.percentile(cli_total_num_bytes, 99), 1), 2)
    cli_mbps_mean = round(nbytes_to_mibps(float(sum(cli_total_num_bytes)) / len(cli_total_num_bytes), 1), 2)

    print(str(cli_mbps_0) + "\t" + str(cli_mbps_50) + "\t" +
            str(cli_mbps_99) + "\t" + str(cli_mbps_mean))
#

# Totals of packets and bytes for each measurement, i.e. index 0
# holds the total packets and bytes sent at the first measurement, etc.
cli_total_num_packets = []
cli_total_num_bytes = []

if server_log is not None:
    with open(server_log) as f:
        first = True
        prev_pkt = None
        prev_byt = None
        for line in f:
            if line.startswith("        RX packets"):
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

    print("Server measurements:")
    print(cli_total_num_bytes)
    #cli_total_num_packets = cli_total_num_packets[3:-3]
    #cli_total_num_bytes = cli_total_num_bytes[3:-3]
    cli_mpps_0 = round(npkts_to_mpps(numpy.percentile(cli_total_num_packets, 0), 5), 2)
    cli_mpps_50 = round(npkts_to_mpps(numpy.percentile(cli_total_num_packets, 50), 5), 2)
    cli_mpps_99 = round(npkts_to_mpps(numpy.percentile(cli_total_num_packets, 99), 5), 2)
    cli_mpps_mean = round(npkts_to_mpps(float(sum(cli_total_num_packets)) / len(cli_total_num_packets), 5), 2)

    if cli_mpps_99 < .01:
        cli_mpps_0 = round(npkts_to_kpps(numpy.percentile(cli_total_num_packets, 0), 5), 2)
        cli_mpps_50 = round(npkts_to_kpps(numpy.percentile(cli_total_num_packets, 50), 5), 2)
        cli_mpps_99 = round(npkts_to_kpps(numpy.percentile(cli_total_num_packets, 99), 5), 2)
        cli_mpps_mean = round(npkts_to_kpps(float(sum(cli_total_num_packets)) / len(cli_total_num_packets), 5), 2)

    cli_mbps_0 = round(nbytes_to_mibps(numpy.percentile(cli_total_num_bytes, 0), 5), 2)
    cli_mbps_50 = round(nbytes_to_mibps(numpy.percentile(cli_total_num_bytes, 50), 5), 2)
    cli_mbps_99 = round(nbytes_to_mibps(numpy.percentile(cli_total_num_bytes, 99), 5), 2)
    cli_mbps_mean = round(nbytes_to_mibps(float(sum(cli_total_num_bytes)) / len(cli_total_num_bytes), 5), 2)

    print(str(cli_mbps_0) + "\t" + str(cli_mbps_50) + "\t" +
            str(cli_mbps_99) + "\t" + str(cli_mbps_mean))
#    str(gk_mpps_50) + "\t" +
#    str(gk_mpps_99) + "\t" +
#    str(gk_mpps_mean) + "\t" +
