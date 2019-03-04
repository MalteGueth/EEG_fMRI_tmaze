### Feb. 25th - Mar. 3rd
* In order to improve the overall documentation of the study, I took a couple of measures to update the study repository

  * To enable a better insight into the structure of the research project, I uploaded a rough draft
  for a readme that would guide readers through the preprocessing and analyses.
  
  * For a start, I focused on converting prior analyses into jupyter notebooks, but only managed to finish
  the preprocessing bits. There are still some flaws to correct (i.e. no correction for eeg marker timings,
  only cluster images for first level MRI examples, no coordinates for peak values in functional clusters, etc)
  
  * Although the overall fMRI data quality for the three pilot sets seems fine, I have to do more work on.
  quality control before the real recruitment. That way I can figure out the ideal preprocessing modules.
  
* I sat down with my new RA and continued teaching him about the basic principles of simultaneous EEG-fMRI. Moreover, we planned a trial run at Baker and Krekelberg lab (with EEG, GPS, ECG, but no MRI) to acquaint him with the preparation procedures.

* Next week, I'll present the results from piloting the experiment in our lab meeting, so I started working on sumamrizing and creating slides.

* During a couple of trial runs for performing T1-informed source localizations for the reward positivity and NT170, I was pondering what would enable better fits: 1) Including electrodes in EGI's sensor net which a located on the face (effectively making them EMG) 2) Excluding everything that might to far off to be considered EEG

  * It might be a worthwhile comparison to perform source localizations with both solutions to check which one produces the     better fit.
  
  * In my first few comparisons for a single subject it seemed like including more electrodes decreased fits and had a higher   suscebtibility for locating dipoles outside the brain. 

* In an effort to save on copmutational time with incoming subject data (and with exisiting data from other studies), I requested access to Rutgers' Amarel cluster. Most of the software essential to me (Python 2.7, 3.6, R, Matlab, FSL, etc) seems to be installed already with some exceptions (i.e. FreeSurfer, simnibs, MNE).
