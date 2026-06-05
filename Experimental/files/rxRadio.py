#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: SingleRX1
# GNU Radio version: 3.10.12.0

from gnuradio import blocks
from gnuradio import filter
from gnuradio.filter import firdes
from gnuradio import gr
from gnuradio.fft import window
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio import zeromq
from xmlrpc.server import SimpleXMLRPCServer
import threading
import osmosdr
import time

# I renamed out_pluto to txRadio but not SingleRX1 -> rxRadio; do when possible, dont wanna do w/o test and break.

class SingleRX1(gr.top_block):

    def __init__(self, freq_channels=3):
        gr.top_block.__init__(self, "SingleRX1", catch_exceptions=True)
        self.flowgraph_started = threading.Event()

        ##################################################
        # Variables
        ##################################################
        self.freq_start = freq_start = 500e3
        self.freq_end = freq_end = 1e6
        self.freq_channels = freq_channels
        self.temp = temp = (freq_end-freq_start)/freq_channels
        self.samp_rate = samp_rate = 3e6
        self.freq = freq = 915e6

        # ZMQ port start
        portStart = 55555

        ##################################################
        # Blocks
        ##################################################

        # detect local 10.1.* IP
        import socket
        def _get_local_ip(prefix='10.1.'):
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.connect(('10.1.1.1', 1))
                ip = s.getsockname()[0]
                s.close()
                if ip.startswith(prefix):
                    return ip
            except Exception:
                pass
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.connect(('8.8.8.8', 53))
                ip = s.getsockname()[0]
                s.close()
                if ip.startswith(prefix):
                    return ip
            except Exception:
                pass
            try:
                hostname = socket.gethostname()
                for res in socket.getaddrinfo(hostname, None):
                    candidate = res[4][0]
                    if candidate.startswith(prefix):
                        return candidate
            except Exception:
                pass
            return None

        self.local_ip = _get_local_ip()
        if self.local_ip is None:
            print('Warning: could not detect a 10.1.* IP address. Set to 0.0.0.0')
            host_for_xmlrpc = ('0.0.0.0', 8080)
            zmq_host = '0.0.0.0'
        else:
            host_for_xmlrpc = (self.local_ip, 8080)
            zmq_host = self.local_ip

        self.zmq_sinks = []
        for i in range(int(self.freq_channels)):
            port = portStart + i
            zmq_addr = f'tcp://{zmq_host}:{port}'
            sink = zeromq.pub_sink(gr.sizeof_float, 1, zmq_addr, 100, False, (-1), '', True, True)
            self.zmq_sinks.append(sink)

        self.xmlrpc_server_0 = SimpleXMLRPCServer(host_for_xmlrpc, allow_none=True)
        self.xmlrpc_server_0.register_instance(self)
        self.xmlrpc_server_0_thread = threading.Thread(target=self.xmlrpc_server_0.serve_forever)
        self.xmlrpc_server_0_thread.daemon = True
        self.xmlrpc_server_0_thread.start()
        self.rtlsdr_source_0 = osmosdr.source(
            args="numchan=" + str(1) + " " + ""
        )
        self.rtlsdr_source_0.set_time_unknown_pps(osmosdr.time_spec_t())
        self.rtlsdr_source_0.set_sample_rate(samp_rate)
        self.rtlsdr_source_0.set_center_freq(freq, 0)
        self.rtlsdr_source_0.set_freq_corr(0, 0)
        self.rtlsdr_source_0.set_dc_offset_mode(2, 0)
        self.rtlsdr_source_0.set_iq_balance_mode(2, 0)
        self.rtlsdr_source_0.set_gain_mode(True, 0)
        self.rtlsdr_source_0.set_gain(10, 0)
        self.rtlsdr_source_0.set_if_gain(20, 0)
        self.rtlsdr_source_0.set_bb_gain(20, 0)
        self.rtlsdr_source_0.set_if_gain(0, 0)
        self.rtlsdr_source_0.set_bb_gain(0, 0)
        self.rtlsdr_source_0.set_antenna('', 0)
        self.rtlsdr_source_0.set_bandwidth(samp_rate, 0)

        self.bandpass_filters = []
        self.power_blocks = []
        self.integrate_blocks = []
        self.log_blocks = []

        temp = (self.freq_end - self.freq_start) / self.freq_channels
        channel_centers = [self.freq_start + temp/2 + temp*i for i in range(int(self.freq_channels))]

        for i, center in enumerate(channel_centers):
            rel_center = center
            bandwidth = temp * 0.8  # 80% of channel width
            low_cutoff = max(0, rel_center - bandwidth/2)
            high_cutoff = min(samp_rate / 2, rel_center + bandwidth/2)
            transition_width = bandwidth / 10
            if low_cutoff >= high_cutoff:
                low_cutoff = rel_center - bandwidth/4
                high_cutoff = rel_center + bandwidth/4
            taps = firdes.band_pass(1.0, samp_rate, low_cutoff, high_cutoff, transition_width, window.WIN_HAMMING, 6.76)
            bp_filter = filter.fir_filter_ccf(1, taps)
            self.bandpass_filters.append(bp_filter)

            power_block = blocks.complex_to_mag_squared(1)
            self.power_blocks.append(power_block)

            integrate_block = blocks.moving_average_ff(2500, 1.0/2500, 4000, 1)
            self.integrate_blocks.append(integrate_block)

            log_block = blocks.nlog10_ff(10, 1, 0)
            self.log_blocks.append(log_block)


        ##################################################
        # Connections
        ##################################################
        for bp in self.bandpass_filters:
            self.connect((self.rtlsdr_source_0, 0), (bp, 0))

        for i, (bp, power, integ, logb) in enumerate(zip(self.bandpass_filters, self.power_blocks, self.integrate_blocks, self.log_blocks)):
            self.connect((bp, 0), (power, 0))
            self.connect((power, 0), (integ, 0))
            self.connect((integ, 0), (logb, 0))
            self.connect((logb, 0), (self.zmq_sinks[i], 0))


    # I had a few artifacts here from code I attempted but failed, a few might remain havent been thorough but it works.
    def get_freq_start(self):
        return self.freq_start

    def set_freq_start(self, freq_start):
        self.freq_start = freq_start
        self.set_temp((self.freq_end-self.freq_start)/self.freq_channels)
        try:
            self.channel_proc.set_num_channels(int(self.freq_channels))
        except Exception:
            pass

    def get_freq_end(self):
        return self.freq_end

    def set_freq_end(self, freq_end):
        self.freq_end = freq_end
        self.set_temp((self.freq_end-self.freq_start)/self.freq_channels)
        try:
            self.channel_proc.set_num_channels(int(self.freq_channels))
        except Exception:
            pass

    def get_freq_channels(self):
        return self.freq_channels

    def set_freq_channels(self, freq_channels):
        self.freq_channels = freq_channels
        self.set_temp((self.freq_end-self.freq_start)/self.freq_channels)
        try:
            self.channel_proc.set_num_channels(int(self.freq_channels))
        except Exception:
            pass

    def get_temp(self):
        return self.temp

    def set_temp(self, temp):
        self.temp = temp
        try:
            self.channel_proc.set_num_channels(int(self.freq_channels))
        except Exception:
            pass

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.rtlsdr_source_0.set_sample_rate(self.samp_rate)
        self.rtlsdr_source_0.set_bandwidth(self.samp_rate, 0)

    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self.rtlsdr_source_0.set_center_freq(self.freq, 0)




def main(top_block_cls=SingleRX1, options=None):
    parser = ArgumentParser()
    parser.add_argument('-c', '--channels', type=int, default=3, help='Number of channels')
    args = parser.parse_args()
    tb = top_block_cls(freq_channels=args.channels)

    def sig_handler(sig=None, frame=None):
        tb.stop()
        tb.wait()

        sys.exit(0)

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    tb.start()
    tb.flowgraph_started.set()

    try:
        input('Press Enter to quit: ')
    except EOFError:
        pass
    tb.stop()
    tb.wait()


if __name__ == '__main__':
    main()
