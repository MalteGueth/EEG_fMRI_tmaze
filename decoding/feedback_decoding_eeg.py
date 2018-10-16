"""
Created on Tue Oct 16 08:06:02 2018

@author: Malte Gueth
"""

# Pre-processing, epoching, decoding and generalized decoding across time
# Decoding and plotting based on mne_notebook_3_mvpa.ipynb 
# by Jona Sassenhagen (https://github.com/jona-sassenhagen)
# https://github.com/jona-sassenhagen/mne_workshop_amsterdam/blob/master/mne_notebook_3_mvpa.ipynb


##### Epoching

import glob
import os

import mne

path = './raw/'
for file in glob.glob(os.path.join(path, 'ICA-raw.fif')):
    
    filepath, filename = os.path.split(file)
    filename, ext = os.path.splitext(filename)    
    
    raw = mne.io.read_raw_fif(file, preload=True) 
    picks = mne.pick_types(raw.info, eeg=True, eog=False)
        
    events = mne.find_events(raw, min_duration=0.001)
    event_id = {'reward': 1, 'no_reward': 2}
    
    epochs = mne.Epochs(raw, events=events, event_id=event_id, tmin=-2, tmax=2.5,
                        baseline=(-0.25, 0), picks=picks, preload=True)
    
    epochs.resample(250) 
    
    epochs.save('./epochs/' + filename[:-8] + '-epo.fif')
    
##### Decoding

from sklearn.svm import LinearSVC
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from mne.decoding import Vectorizer, SlidingEstimator, cross_val_multiscore, GeneralizingEstimator

import numpy as np

path = './epochs/'

for file in glob.glob(os.path.join(path, '*-epo.fif')):
    
    epochs = mne.read_epochs(path, preload=True)
    epochs.crop(tmin=-0.5, tmax=epochs.tmax)
    epochs_eq = epochs.copy().equalize_event_counts(['reward','no_reward'])[0]

    X=epochs_eq['reward','no_reward'].get_data()
    y=epochs_eq['reward','no_reward'].events[:,2]
    
    clf = make_pipeline(Vectorizer(), StandardScaler(),
                    LinearSVC(class_weight='balanced')
                   )
    clf.fit(X, y)
    
    sl = SlidingEstimator(clf)
    scores_time_decoding = cross_val_multiscore(sl, X, y)
    if file == './epochs/101-epo.fif':
        scores_td = scores_time_decoding
    else:
        scores_td = np.append(scores_td, scores_time_decoding, axis=0)
    
    gen = GeneralizingEstimator(clf, scoring='roc_auc')
    scores_gat = cross_val_multiscore(gen, X, y)
    if file == './epochs/101-epo.fif':
        scores_gat = scores_gat
    else:
        scores_gat = np.append(scores_gat, scores_gat, axis=0)
                
###### Plot decoding results

import matplotlib.pyplot as plt
      
fig, ax = plt.subplots()
ax.plot(epochs.times, scores_td.T)
plt.show()

fig, ax = plt.subplots()
ax.plot(epochs.times, scores_td.mean(0))
plt.show()

#vmax = np.abs(data).max()
tmin, tmax = epochs.times[[0, -1]]

fig, ax = plt.subplots()
im = ax.imshow(
    scores_gat.mean(0),
    origin="lower", cmap="RdBu_r",
    extent=(tmin, tmax, tmin, tmax),
    vmax=0.7, vmin=0.3);
ax.axhline(0., color='k')
ax.axvline(0., color='k')
plt.colorbar(im)
