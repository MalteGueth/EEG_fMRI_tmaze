"""
Created on Sat Oct  27 09:45:16 2018
@author: Malte Gueth
"""

import mne

import numpy as np
import matplotlib.pyplot as plt

file = './sub1_tf-epo.fif'  

epochs = mne.read_epochs(file, preload=True)

decim = 3
freqs = np.logspace(*np.log10([1, 50]),num=30)
sfreq = 250
cycles = np.logspace(*np.log10([1, 10]), num=len(freqs))

reward_evo = epochs['reward'].average()
no_reward_evo = epochs['no_reward'].average()

tfr_epochs_reward = mne.time_frequency.tfr_morlet(epochs['reward'], freqs, n_cycles=cycles, 
                                                  decim=decim, average=True, 
                                                  return_itc=False, n_jobs=1,
                                                  use_fft=True, output='power')
tfr_epochs_reward = tfr_epochs_reward.apply_baseline(mode='logratio',
                                                     baseline=(-1., -.5))
power_reward = tfr_epochs_reward.data

tfr_epochs_noreward = mne.time_frequency.tfr_morlet(epochs['no_reward'], freqs, n_cycles=cycles, 
                                                    decim=decim, average=True, 
                                                    return_itc=False, n_jobs=1,
                                                    use_fft=True, output='power')  
tfr_epochs_noreward = tfr_epochs_noreward.apply_baseline(mode='logratio',
                                                         baseline=(-1., -.5))
power_noreward = tfr_epochs_noreward.data

times = 1e3 * tfr_epochs_reward.times[90:140,]
colors = dict(reward = "darkred", no_reward = "darkblue")
linestyles = dict(reward = '-', no_reward = '--')
pick = ch_names.index('E8')
evoked_dict = {'reward': reward, 'no_reward': no_reward}

sub1_feed = plt.figure()
plt.subplots_adjust(0.12, 0.08, 0.96, 1.2, 0.2, 0.43)
vmax = np.max(np.abs())
vmin = -vmax
plt.subplot(3, 1, 1)
mne.viz.plot_compare_evokeds(evoked_dict, picks=pick, truncate_yaxis=False, truncate_xaxis=False,
                             invert_y=True, ci=0.9, linestyles=linestyles, 
                             colors=colors, ylim = dict(eeg=[-8,8]))
plt.subplot(3, 1, 2)
plt.imshow(power_reward[pick,:,110:150], cmap=plt.cm.RdBu_r,
           extent=[times[0], times[-1], freqs[0], freqs[-1]],
           aspect='auto', origin='lower', vmin=-0.4, vmax=0.4)
plt.subplot(3, 1, 1)
plt.imshow(power_reward[pick,:,110:150], cmap=plt.cm.RdBu_r,
           extent=[times[0], times[-1], freqs[0], freqs[-1]],
           aspect='auto', origin='lower', vmin=-0.4, vmax=0.4)
           
