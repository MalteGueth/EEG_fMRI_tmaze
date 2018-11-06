"""
Created on Tue Aug 19 17:10:05 2018

@author: maltegueth
"""

import mne

from mne.preprocessing import ICA
from mne.preprocessing import create_ecg_epochs

# Load EGI file
file = './Tmaze_EEG/file.mff'
raw = mne.io.read_raw_egi(file, preload=True)

# Look for events, define event IDs
events = mne.find_events(raw)

# Labels/IDs for the triggers are coded as additional stimulus channels in the EGI file
# Use raw.info to display them and define IDs
raw.info['ch_names']
event_id = {'reward': 1, 'no_reward': 2, 'response_1': 3,
            'response_2': 4, 'bgin_1': 5, 'bgin_2': 6,
            'bgin_3': 7, 'trsp_1': 8, 'trsp_2': 9,
            'choc_1': 10, 'choc_2': 11, 'chos_1': 12,
            'chos_2': 13, 'strt_1': 14, 'strt_2': 15,
            'turn_1': 16, 'turn_2': 17, 'cell_1': 18,
            'cell_2': 19, 'cell_3': 20, 'sess': 21,
            'trev': 22, 'boundary': 23
            }
            
# Just to check on the distribution, plot the event IDs across time
onsets = mne.viz.plot_events(events, raw.info['sfreq'], raw.first_samp, 
                             color=None, event_id=event_id)
                             
# Filter, re-reference, and down-sample the data for faster ICA processing                           
raw = raw.filter(0.1,50)
raw = raw.set_eeg_reference('average')
raw = raw.resample(250)
events = mne.find_events(raw)

# Define ICA parameters
n_components = 60  
method = 'extended-infomax'
decim = None
reject = None

ica = ICA(n_components=n_components, method=method) 
ica.fit(raw, picks=None, decim=decim, reject=reject) 

# Plot components or their specific properties

ica.plot_components() 
ica.plot_properties(raw, picks=0) 

# Create ECG epochs around heart beats and average them ,
# excluding data sections which represent large outliers if necessary
# Rejection parameters are based on peak-to-peak amplitude
ecg_average = create_ecg_epochs(raw, reject=None).average()

# Correlate the ECG epochs to all ICA components' source signal time courses
# Build artifact scores via the correlation anaylsis
ecg_epochs = create_ecg_epochs(raw, reject=None)
ecg_inds, scores = ica.find_bads_ecg(ecg_epochs)

# Plot the artifact scores / correlations across ICA components
# and retrieve component numbers of sources likely representing
# ballistocardiac artifacts
fig=ica.plot_scores(scores, title='ICA component scores',
                    exclude=ecg_inds, 
                    show=True, 
                    axhline=0.4)

# To improve your selection, inspect the ica components' 
# source signal time course and compare it to the average ecg artifact 
ica.plot_sources(ecg_average, exclude=ecg_inds)  

# If no fruther artifact rejection improvement is required, use the ica.apply
# for ica components to be zeroed out and removed from the signal
# Enter an array of bad indices in exclude to remove components
# start and end arguments mark the first and last sample of the set to be
# affected by the removal
ica.apply(raw, exclude=[])
    
# Epoch and average data
tmin, tmax = -0.2, 0.8
epochs = mne.Epochs(raw, events=events, event_id=event_id, 
                    picks=picks, tmin=tmin, tmax=tmax,
                    preload=True, baseline=None)
                    
reward = epochs['reward'].average()
no_reward = epochs['no_reward'].average()

# Plot results
reward.plot_joint()
reward.plot_joint()

# An alterntive approach for epoching would be to import the event file from
# the fMRI analysis and re-arrange it to the event file format, so
# that you end up with a set of trials for each feedback, direction, and
# context combination.
# 

# Create virtual channel for EGI
reward = epochs[reward_left_maze+reward_right_maze].average()
reward.apply_baseline(baseline=(-0.2,0))
data = reward.data

FCz= np.array([data[22], data[14], data[5],
               data[6], data[7], data[8], data[14]]).mean(axis=0)
P8= np.array([data[170], data[177], data[178], 
              data[169], data[168], data[160], data[159]]).mean(axis=0)
data[14] = FCz
data[169] = P8
reward.data = data

no_reward = epochs[no_reward_left_maze+no_reward_right_maze].average()
no_reward.apply_baseline(baseline=(-0.2,0))
data_norew = no_reward.data

FCz= np.array([data_norew[22], data_norew[14], data_norew[5],
               data_norew[6], data_norew[7], data_norew[8], data_norew[14]]).mean(axis=0)
P8= np.array([data_norew[170], data_norew[177], data_norew[178], 
              data_norew[169], data_norew[168], data_norew[160], data_norew[159]]).mean(axis=0)
data_norew[14] = FCz
data_norew[169] = P8
no_reward.data = data_norew

# Compute difference wave
difference_wave = mne.combine_evoked((reward,no_reward),[-1,1])

# Plot new channels and difference wave
colors = dict(Reward_maze = "darkblue", No_reward_maze = "darkred", 
              Difference_Wave = 'black')
evoked_dict = {'Reward_maze': evoked1, 'No_reward_maze': evoked2, 
               'Difference_Wave': difference_wave}
linestyles = dict(Reward_maze = '-', No_reward_maze = '--', 
                  Difference_Wave = '-')
ch_name=''
picks=evoked1.ch_names.index(ch_name)

fig=mne.viz.plot_compare_evokeds(evoked_dict, picks=picks, 
                                  truncate_yaxis=False, truncate_xaxis=False,
                                  colors=colors, linestyles=linestyles,
                                  invert_y=True, ylim = dict(eeg=[-8,8]),
                                  title='Feedback related responses during maze trials',
                                  show_sensors=True)

# Export
index, scaling_time = ['epoch', 'time'], 1e3
epochs = '/sub1_preprocessed_epochs.fif'
df = epochs.to_data_frame(picks=None, scalings=None, scaling_time=scaling_time, index=index)  
df_all.to_csv('/path/sub1_epochs.csv')
