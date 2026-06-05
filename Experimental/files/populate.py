#!/usr/bin/env python3
import argparse
import subprocess
import sys
import os

parser = argparse.ArgumentParser(description='Distribute rxRadio.py to target nodes')
parser.add_argument('-r', '--range', help='Range of last digits')
parser.add_argument('-l', '--list', help='Comma-separated list of last digits')
parser.add_argument('-L', '--Ltargets', help='Whitespace-separated list of full IPs (usually given default)')
parser.add_argument('--user', default='ucanlab', help='username')
parser.add_argument('--remote-dir', default='/home/ucanlab/Downloads', help='directory to copy to')
parser.add_argument('--file', default='rxRadio.py', help='Local file to distribute')
parser.add_argument('--extra-files', nargs='*', default=[], help='Additional files to distribute')
args = parser.parse_args()

if not (args.range or args.list or args.Ltargets): # This shoudlnt ever trigger - - - just in case
    print('Error: must provide -r or -l or -L')
    parser.print_help()
    sys.exit(2)

ips = []
if args.range:
    try:
        start_s, end_s = args.range.split(',')
        start = int(start_s)
        end = int(end_s)
        if start > end:
            start, end = end, start
        for i in range(start, end+1):
            ips.append(f'10.1.1.{i}')
    except Exception as e:
        print('Invalid range')
        sys.exit(1)

if args.list:
    parts = [p.strip() for p in args.list.split(',') if p.strip()]
    for p in parts:
        try:
            i = int(p)
            ips.append(f'10.1.1.{i}')
        except:
            print(f'Invalid list')
            sys.exit(1)

if args.Ltargets:
    parts = args.Ltargets.split()
    ips.extend(parts)

seen = set()
ips2 = []
for ip in ips:
    if ip not in seen:
        seen.add(ip)
        ips2.append(ip)
ips = ips2

files_to_copy = [args.file] + args.extra_files
for f in files_to_copy:
    if not os.path.isfile(f):
        print(f'Local file {f} not found in current directory.')
        sys.exit(1)

print(f'Distributing {len(files_to_copy)} file(s) to {len(ips)} host(s)')
for ip in ips:
    for f in files_to_copy:
        dest = f"{args.user}@{ip}:{args.remote_dir}/"
        print(f'Copying {f} to {ip}...')
        try:
            subprocess.check_call(['scp', f, dest])
            if f == args.file:
                ssh_cmd = f"ssh {args.user}@{ip} 'chmod +x {os.path.join(args.remote_dir, f)}'"
                subprocess.check_call(ssh_cmd, shell=True)
            print(f'Successfully populated {ip} with {f}')
        except subprocess.CalledProcessError as e:
            print(f'Failed for {ip} with {f}: {e}')

print('Populate complete')
