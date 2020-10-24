from pathlib import Path
import sys
import statistics
import numpy
from datetime import datetime

def npkts_to_mpps(npkts, sec):
    return npkts / float(sec) / 1000. / 1000.

def npkts_to_kpps(npkts, sec):
    return npkts / float(sec) / 1000.

def nbytes_to_gibps(nbytes, sec):
    return nbytes / float(sec) * 8. / 1024. / 1024. / 1024.

def nbytes_to_mibps(nbytes, sec):
    return nbytes / float(sec) * 8. / 1024. / 1024.

if len(sys.argv) != 2:
    print("Need test_name/experiment_name")
    sys.exit()

gk_log = 'results/' + sys.argv[1] + '/gatekeeper.log'
client_log = 'results/' + sys.argv[1] + '/client_ifconfig.txt'
server_log = 'results/' + sys.argv[1] + '/server_ifconfig.txt'
legit_log = 'results/' + sys.argv[1] + '/legit_log.txt'

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
    gk_total_num_packets = gk_total_num_packets[1:-1]
    gk_total_num_bytes = gk_total_num_bytes[1:-1]
    print(gk_total_num_bytes)
    gk_mibps_0 = round(nbytes_to_mibps(numpy.percentile(gk_total_num_bytes, 0), 15), 2)
    gk_mibps_50 = round(nbytes_to_mibps(numpy.percentile(gk_total_num_bytes, 50), 15), 2)
    gk_mibps_99 = round(nbytes_to_mibps(numpy.percentile(gk_total_num_bytes, 99), 15), 2)
    gk_mibps_mean = round(nbytes_to_mibps(float(sum(gk_total_num_bytes)) / len(gk_total_num_bytes), 15), 2)

    print(str(gk_mibps_0) + "\t" + str(gk_mibps_50) + "\t" +
            str(gk_mibps_99) + "\t" + str(gk_mibps_mean))

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

# Totals of packets and bytes for each measurement, i.e. index 0
# holds the total packets and bytes sent at the first measurement, etc.
cli_total_num_packets = []
cli_total_num_bytes = []

if Path(server_log).is_file():
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

completed = []
duration = []
connections = {}
if legit_log is not None:
    with open(legit_log) as f:
        for line in f:
            tokens = line.split()

            if len(tokens) == 0:
                continue

            if tokens[1] != 'IP':
                continue

            if tokens[-1] == '(ipip-proto-4)':
                offset = 4
                if tokens[2] != '172.31.0.150' or tokens[4] != '172.31.1.43:':
                    continue
            else:
                offset = 0
                if not tokens[2].startswith('172.31.0.150') or not tokens[4].startswith('172.31.3.200'):
                    continue

            if tokens[6 + offset] == '[S],':
                port = tokens[2 + offset].split(sep=".")[4]
                if port not in connections:
                    time_start = datetime.strptime(tokens[0], '%H:%M:%S.%f')
                    connections[port] = (time_start, False, None)

            if (tokens[7 + offset] == 'ack' and tokens[8 + offset] == '2,') or \
                    tokens[6 + offset] == '[F.],':
                port = tokens[2 + offset].split(sep=".")[4]
                if port not in connections:
                    print("Connection not found")
                    quit()
                time_stop = datetime.strptime(tokens[0], '%H:%M:%S.%f')
                connection = connections[port]
                time_start = connection[0]
                d = time_stop - time_start
                duration_ms = d.seconds * 1000 + d.microseconds / 1000
                connections[port] = (time_start, True, duration_ms)

    num_completed = 0
    durations = []
    for port in connections:
        connection = connections[port]
        completed = connection[1]
        duration_ms = connection[2]
        if completed:
            num_completed += 1
            durations.append(duration_ms)
        else:
            durations.append(20000)

    print("Completed " + str(num_completed) + " out of " + str(len(connections)) + " flows")
    duration_0 = round(numpy.percentile(durations, 0), 2)
    duration_50 = round(numpy.percentile(durations, 50), 2)
    duration_99 = round(numpy.percentile(durations, 99), 2)
    duration_mean = round(float(sum(durations)) / len(durations), 2)

    print(str(duration_0) + "\t" + str(duration_50) + "\t" +
            str(duration_99) + "\t" + str(duration_mean))
