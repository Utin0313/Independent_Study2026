import zmq
import time
import numpy as np
import math
import argparse
import csv
import os
import datetime

# Arguments
parser = argparse.ArgumentParser()
parser.add_argument('--pis', nargs="+", help="Node Addresses")
parser.add_argument("-f1", "--freq_start", type=int, default=500000, help="Start Freq (default 500e3)")
parser.add_argument("-f2", "--freq_end", type=int, default=1000000, help="End Freq (default 1e6)")
parser.add_argument("-c", "--freq_channels", type=int, default=3, help="Channels (default 3)")
parser.add_argument("-n", "--new_file", action="store_true", help="Create a new timestamped CSV file")
args = parser.parse_args()
# Still have to fix this but didnt bother for now . . .
# Wanna have files time named on generation - including current working file but can only think of involving memory or a uniquely appended name which is no for now.
# Create filename in dataTaken folder ( I might have added this cant remember nor test ) [dont wanna read]
os.makedirs('dataTaken', exist_ok=True)
if args.new_file:
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"dataTaken/maxPower_POBS_{timestamp}.csv"
    mode = 'w'
else:
    filename = 'dataTaken/maxPower_POBS.csv'
    mode = 'a'

header = ['Channels'] + [str(i + 1) for i in range(args.freq_channels)]
if mode == 'w':
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
elif mode == 'a':
    if not os.path.exists(filename) or os.path.getsize(filename) == 0:
        with open(filename, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(header)
    else:
        with open(filename, 'r', newline='') as f:
            rows = list(csv.reader(f))
        if rows:
            existing_header = rows[0]
            existing_channels = max(0, len(existing_header) - 1)
            desired_channels = max(existing_channels, args.freq_channels)
            if desired_channels != existing_channels:
                new_header = ['Channels'] + [str(i + 1) for i in range(desired_channels)]
                new_rows = [new_header]
                for row in rows[1:]:
                    padded = row + [''] * (desired_channels + 1 - len(row))
                    new_rows.append(padded)
                with open(filename, 'w', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerows(new_rows)

#script config
portStart = 55555


#Simulation param
n_iter = 3 #number of iterations
t_pause = 1 #between iterations
init_pause = 0.2 #between addresses
        

maxPower = [[-999] * args.freq_channels for _ in range(len(args.pis))]
for iter in range(n_iter):
    time.sleep(t_pause)
    for idx, address in enumerate(args.pis):
        time.sleep(init_pause)
        vals = []
        for i in range(args.freq_channels):
            port = portStart + i
            context = zmq.Context()
            socket = context.socket(zmq.SUB)
            socket.connect(f"tcp://{address}:{port}")
            socket.setsockopt(zmq.SUBSCRIBE, b'')
            socket.setsockopt(zmq.RCVTIMEO, 5000)
            try:
                msg = socket.recv()
                val = np.frombuffer(msg, dtype=np.float32)[0]
                vals.append(val)
            except Exception:
                vals.append(-999.0)
            finally:
                socket.close()
                context.term()
        vals = np.array(vals)
        for channel in range(args.freq_channels):
            maxPower[idx][channel] = max(maxPower[idx][channel], float(vals[channel]))
            #print(f"tcp://{address}:{portStart} ||| Iteration {iter+1} ||| Powers: {' '.join(f'{v:.2f}' for v in vals)} dB")
    print(f"Iteration {iter}")

existing_channels = 0
if mode == 'a' and os.path.exists(filename) and os.path.getsize(filename) > 0:
    with open(filename, 'r', newline='') as f:
        rows = list(csv.reader(f))
    if rows:
        existing_channels = max(0, len(rows[0]) - 1)
desired_channels = max(existing_channels, args.freq_channels)

with open(filename, 'a', newline='') as f:
    writer = csv.writer(f)
    for j, power in enumerate(maxPower):
        row_values = [f"Pi.{j+1}"] + [f"{p:05.2f}" for p in power]
        if len(row_values) < desired_channels + 1:
            row_values += [''] * (desired_channels + 1 - len(row_values))
        writer.writerow(row_values)
