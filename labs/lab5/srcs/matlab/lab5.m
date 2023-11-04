%! ------------------------------------------------------------------------
%! SOC Desgin Lab 4
%!  - Create channel filter using a filter chain and model against Xilinx
%!  FIR compiler bit accurate model
%!      - Filter 1: Sample rate = 125Mhz, Fpass = 576kHz, Fstop = 2.549MHz,
%!          Decimation rate: 40, Apass <= .5dB, Astop >= 80dB
%!      - Filter 2: Sample rate = 3.125Mhz, Fpass = 18kHz, Fstop = 30kHz,
%!          Decimation rate: 64, Apass <= .5dB, Astop >= 80dB
%! ------------------------------------------------------------------------

%! Enviorment
clear; close all;
dds_scale       = 2^14;
dds_bit_width   = 16;
scale_val       = 18;
fp_scale        = 2^scale_val;
lo_freq    = 30e6;
rf_freq  = 30.001e6;

%! Read filter coefficents from mat files
mat_filter1 = load("filter1.mat");
mat_filter2 = load("filter2.mat");


%! Create FIR bit accurate models
% Filter 1
filter_bit_acc_1 = fir_compiler_v7_2_bitacc();
config_1 = get_configuration(filter_bit_acc_1);
config_1.coeff = round(mat_filter1.Num * fp_scale);
config_1.data_fract_width = 0;
config_1.output_width = 35;
config_1.output_rounding_mode = 0;
config_1.filter_type = 2;
config_1.decim_rate = 40;
config_1.coeff_fract_width = 0;
config_1.output_fract_width = 15;
filter_bit_acc_1 = fir_compiler_v7_2_bitacc(config_1);

% Filter 2
filter_bit_acc_2 = fir_compiler_v7_2_bitacc();
config_2 = get_configuration(filter_bit_acc_2);
config_2.coeff = round(mat_filter2.Num * fp_scale);
config_2.data_fract_width = 0;
config_2.output_width = 35;
config_2.output_rounding_mode = 0;
config_2.filter_type = 2;
config_2.decim_rate = 64;
config_2.coeff_fract_width = 0;
config_2.output_fract_width = 15;
filter_bit_acc_2 = fir_compiler_v7_2_bitacc(config_2);

%! Create test tones
fs = 125000000;
num_end_samples = 1024;
N = num_end_samples * 40 * 64;
freqs = (0:fs/(1024*40*64):fs-fs/(1024*40*64)) - fs/2;
freqs_low = freqs(1:64*40:end)./(64*40);
sig_from_antenna = round(16384 * sin(2*pi*(0:N-1)*rf_freq/fs));

% Create DDS for mixer
tuner_dds_real = 2^14*cos(-2*pi*lo_freq*(0:N-1)/fs);
tuner_dds_imag = 2^14*sin(-2*pi*lo_freq*(0:N-1)/fs);

% Now, multiply the two signals together in the same way that you will in the fpga
mixer_output_real = sig_from_antenna .* tuner_dds_real;
mixer_output_real = round(mixer_output_real / 2^13);
mixer_output_imag = sig_from_antenna .* tuner_dds_imag;
mixer_output_imag = round(mixer_output_imag / 2^13);

% Filter the signals
filter_output_real = filter(filter_bit_acc_1, mixer_output_real);
filter_output_real = round(filter_output_real / fp_scale);
filter_output_real = filter(filter_bit_acc_2, filter_output_real);
filter_output_real = round(filter_output_real / fp_scale);
filter_output_imag = filter(filter_bit_acc_1, mixer_output_imag);
filter_output_imag = round(filter_output_imag / fp_scale);
filter_output_imag = filter(filter_bit_acc_2, filter_output_imag);
filter_output_imag = round(filter_output_imag / fp_scale);

% Plot
subplot(4,2,1);
plot(sig_from_antenna);
title('Signal from Antenna');
subplot(4,2,2);
plot(freqs,fftshift(20*log10(abs(fft(sig_from_antenna)))));
title('FFT of Signal from Antenna');
subplot(4,2,3);
tuner_dds_complex = tuner_dds_real + j*tuner_dds_imag;
plot(tuner_dds_real);
hold on;
plot(tuner_dds_imag);
hold off;
title('Tuner DDS');
subplot(4,2,4);
plot(freqs,fftshift(20*log10(abs(fft(tuner_dds_complex)))));
title('FFT of tuner DDS');
subplot(4,2,5);
plot(mixer_output_real);
hold on;
plot(mixer_output_imag);
hold off;
title('Mixer Output');
subplot(4,2,6);
mixer_output_complex = mixer_output_real + j*mixer_output_imag;
plot(freqs,fftshift(20*log10(abs(fft(mixer_output_complex)))));
title('FFT of mixer output');
subplot(4,2,7);
plot(filter_output_real);
hold on;
plot(filter_output_imag);
hold off;
title('Filter Output');
subplot(4,2,8);
filter_output_complex = filter_output_real + j*filter_output_imag;
plot(freqs_low,fftshift(20*log10(abs(fft(filter_output_complex)))));
title('FFT of filter output');