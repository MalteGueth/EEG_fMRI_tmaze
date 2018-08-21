"""
Created on Tue Aug 19 17:10:05 2018

@author: maltegueth
"""

import mne

from mne.preprocessing import ICA
from mne.preprocessing import create_ecg_epochs

# Load EGI file
file = './Tmaze_EEG/TravisPilot_1_20180410_125510.mff'
raw = mne.io.read_raw_egi(file, preload=True)

# Look for events, define event IDs
events = mne.find_events(raw)

# Labels/IDs for the triggers are coded as additional stimulus channels in the EGI file
# Use raw.info to display them and define IDs
raw.info['ch_names']
event_id = {'bgin': 1, 'strt': 2, 'choc': 3,
            'resp': 4, 'chos': 5, 'turn': 6,
            'feed': 7, 'TRSP': 8, 'TREV': 9
            }
            
# Just to check on the distribution, plot the event IDs across time
onsets = mne.viz.plot_events(events, raw.info['sfreq'], raw.first_samp, 
                             color=None, event_id=event_id)
                             
# Filter, re-reference, and down-sample the data for faster ICA processing                           
raw = raw.filter(0.1,30)
raw = raw.set_eeg_reference('average')
raw = raw.resample(250)
events = mne.find_events(raw)

# Define ICA parameters
n_components = 25  
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
tmin, tmax = -0.5, 1
epochs = mne.Epochs(raw, events=events, event_id=event_id, 
                    picks=picks, tmin=tmin, tmax=tmax,
                    preload=True, baseline=(-0.5, 0))
                    
feed = epochs['feed'].average()

# Plot results
feed.plot_joint()
