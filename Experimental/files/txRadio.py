#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: txRadio
# GNU Radio version: 3.10.9.2

from gnuradio import analog
from gnuradio import blocks
from gnuradio import gr
from gnuradio.filter import firdes
from gnuradio.fft import window
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio import iio
from xmlrpc.server import SimpleXMLRPCServer
import threading

class txRadio(gr.top_block):

    def __init__(self, freq_channels=3):
        gr.top_block.__init__(self, "Not titled yet", catch_exceptions=True)

        ##################################################
        # Variables
        ##################################################
        self.freq_start = freq_start = 500e3
        self.freq_end = freq_end = 1e6
        self.freq_channels = freq_channels
        self.temp = temp = (freq_end-freq_start)/freq_channels
        self.samp_rate = samp_rate = 3e6
        self.amps = [1.0] * self.freq_channels  # initialize amplitudes

        ##################################################
        # Blocks
        ##################################################

        self.xmlrpc_server_0 = SimpleXMLRPCServer(('localhost', 8080), allow_none=True)
        self.xmlrpc_server_0.register_instance(self)
        self.xmlrpc_server_0_thread = threading.Thread(target=self.xmlrpc_server_0.serve_forever)
        self.xmlrpc_server_0_thread.daemon = True
        self.xmlrpc_server_0_thread.start()
        self.iio_pluto_sink_0 = iio.fmcomms2_sink_fc32('ip:192.168.2.1' if 'ip:192.168.2.1' else iio.get_pluto_uri(), [True, True], 32768, False)
        self.iio_pluto_sink_0.set_len_tag_key('')
        self.iio_pluto_sink_0.set_bandwidth(2000000)
        self.iio_pluto_sink_0.set_frequency(915000000)
        self.iio_pluto_sink_0.set_samplerate(3000000)
        self.iio_pluto_sink_0.set_attenuation(0, 10.0)
        self.iio_pluto_sink_0.set_filter_params('Auto', '', 0, 0)

        self.sig_sources = []
        for i in range(self.freq_channels):
            src = analog.sig_source_c(samp_rate, analog.GR_COS_WAVE, 0, 0, 0, 0)  # start with freq=0, amp=0
            self.sig_sources.append(src)

        self.adders = []
        inputs = self.sig_sources[:]
        while len(inputs) > 1:
            new_inputs = []
            for i in range(0, len(inputs), 2):
                if i + 1 < len(inputs):
                    add = blocks.add_cc()
                    self.adders.append(add)
                    self.connect((inputs[i], 0), (add, 0))
                    self.connect((inputs[i + 1], 0), (add, 1))
                    new_inputs.append(add)
                else:
                    new_inputs.append(inputs[i])
            inputs = new_inputs
        self.final_adder = inputs[0]

        self.blocks_add_const_vxx_0 = blocks.add_const_cc(0)  # will be set in update_channels
        self.blocks_multiply_const_vxx_0 = blocks.multiply_const_cc(1)  # will be set

        ##################################################
        # Connections
        ##################################################
        self.connect((self.final_adder, 0), (self.blocks_add_const_vxx_0, 0))
        self.connect((self.blocks_add_const_vxx_0, 0), (self.blocks_multiply_const_vxx_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.iio_pluto_sink_0, 0))

        self.update_channels()

    def update_channels(self):
        """Update frequencies and amplitudes for active channels."""
        self.temp = (self.freq_end - self.freq_start) / self.freq_channels
        for i in range(self.freq_channels):
            f = self.freq_start + self.temp / 2 + self.temp * i
            a = self.amps[i]
            self.sig_sources[i].set_frequency(f)
            self.sig_sources[i].set_amplitude(a)
        
        total_amp = sum(self.amps)
        self.blocks_add_const_vxx_0.set_k(total_amp)
        self.blocks_multiply_const_vxx_0.set_k(1/(2*total_amp) if total_amp != 0 else 1)

    # Shouldnt be any artifacts here.
    def get_freq_start(self):
        return self.freq_start

    def set_freq_start(self, freq_start):
        self.freq_start = freq_start
        self.update_channels()

    def get_freq_end(self):
        return self.freq_end

    def set_freq_end(self, freq_end):
        self.freq_end = freq_end
        self.update_channels()

    def get_freq_channels(self):
        return self.freq_channels

    def set_freq_channels(self, freq_channels):
        self.freq_channels = freq_channels
        self.update_channels()

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        for src in self.sig_sources:
            src.set_sampling_freq(self.samp_rate)

    def set_amps(self, amp_list):
        #"""Set amplitudes for all channels. Expects a list/sequence of floats."""
        try:
            for i, a in enumerate(amp_list):
                if i < self.freq_channels:
                    self.amps[i] = float(a)
        except Exception:
            pass
        self.update_channels()




def main(top_block_cls=txRadio, options=None):
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

    tb.wait()


if __name__ == '__main__':
    main()
