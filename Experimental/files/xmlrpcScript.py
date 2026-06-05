import xmlrpc.client
from xmlrpc.client import ServerProxy
import time
import argparse
import random
import json
import os

# Setup Arguments
parser = argparse.ArgumentParser()
parser.add_argument('--pis', nargs="+", help="Node Addresses")
parser.add_argument("-f1", "--freq_start", type=int, default=500000, help="Start Freq (default 500e3)")
parser.add_argument("-f2", "--freq_end", type=int, default=1000000, help="End Freq (default 1e6)")
parser.add_argument("-c", "--freq_channels", type=int, default=3, help="Channels (default 3)")
parser.add_argument("-z", "--randomize", action="store_true", help="Randomize gains; otherwise use saved values")

args = parser.parse_args()
print(f"Frequency {args.freq_start}-{args.freq_end} with {args.freq_channels} channel(s).")

freq_start = float(args.freq_start)
freq_end = float(args.freq_end)
channels = int(args.freq_channels)
temp = (freq_end - freq_start) / channels
freqs = [freq_start + temp/2.0 + temp*i for i in range(channels)]

gains_file = "channelGains.json"
if args.randomize or not os.path.exists(gains_file):
    gains = [random.uniform(0.0, 100.0) for _ in range(channels)]
    with open(gains_file, 'w') as f:
        json.dump(gains, f)
    if args.randomize:
        print(f"Generated new random gains (saved to {gains_file})")
    else:
        print(f"No previous gains found; generating new ones (saved to {gains_file})")
else:
    with open(gains_file, 'r') as f:
        gains = json.load(f)
    print(f"Using saved gains from {gains_file}")

print("Channel list:")
for f, g in zip(freqs, gains):
    if f >= 1e6:
        fstr = f"{f/1e6:.3f} MHz"
    else:
        if f % 1000 == 0:
            fstr = f"{int(f/1000)} kHz"
        else:
            fstr = f"{f/1000:.3f} kHz"
    print(f"{fstr:12s}: {g:8.4f} amplitude")

try:
    xc = ServerProxy('http://localhost:8080')
    xc.set_freq_start(int(freq_start))
    xc.set_freq_end(int(freq_end))
    xc.set_freq_channels(channels)
    try:
        xc.set_amps(gains)
    except Exception:
        # probably will delete this ; just incase while testing
        try:
            if len(gains) > 0:
                xc.set_amp1(float(gains[0]))
            if len(gains) > 1:
                xc.set_amp2(float(gains[1]))
            if len(gains) > 2:
                xc.set_amp3(float(gains[2]))
        except Exception:
            pass
    print("Setup TC")
except Exception as e:
    print(f"Failed to setup TC: {e}")

for pi in args.pis:
    try:
        xc = ServerProxy(f"http://{pi}:8080")
        xc.set_freq_start(int(freq_start))
        xc.set_freq_end(int(freq_end))
        xc.set_freq_channels(channels)
        try:
            xc.set_amps(gains)
        except Exception:
            # also likely delete
            try:
                if len(gains) > 0:
                    xc.set_amp1(float(gains[0]))
                if len(gains) > 1:
                    xc.set_amp2(float(gains[1]))
                if len(gains) > 2:
                    xc.set_amp3(float(gains[2]))
            except Exception:
                pass
        print(f"Setup {pi}")
    except Exception as e:
        print(f"Failed to setup {pi}: {e}")
