# Adaptive gradient correction
> Performs a gradient artifact correction for EEG data recorded during simultaneous fMRI acquisition which can be informed by movement and heart beat parameters

The functions contained in this repository directory were created to provide a number of adaptive correction approaches
for removing gradient artifacts from EEG signals recorded in the MRI environment. These aim to account
for head movements as well as distortions of the average artifact through ballistocardiac artifacts.

The outlined analyses are adapted from the approaches presented in Allen, Josephs, & Turner (2000) as well as 
Moosmann, Schoenfelder, Specht Scheeringa, Nordby, & Hudgahl (2009). Their original functions can be found in
this _[repository][bergen_toolbox]._

This project is pursued as an assignment for the graduate course 'Scientific Programming in Matlab' (Behavioral
and Neural Sciences Program, Rutgers University Newark). Example data has been collected in the _[Baker Laboratory
for Cognitive Neuroimaging and Stimulation][lap_page]._

![](logo.png)


## Getting Started

### Prerequisites

All of the analyses are written for Matlab R1018b and can be performed without eeglab (see Usage example). 

### Installing

```
under construction
```

### Usage example and typical workflow

First, download the example data set. The folder 'example_data' contains a few exemplary files (ECG, motion data) necessary for performing the analysis. A full workspace with a complete data set (EEG, ECG, motion, experimental information) can be downloaded from the link in the readme in that folder.

When you have the data, make sure you have the following functions on your path: adaptive_weighting_matrix.m, linear_weighting.m, marker_detection.m, qrs_detect.m, realign_euclid.m, realignment_weighting.m, correction_matrix.m and baseline_correct.m
Then use:

```
artifactOnsets = marker_detection(events,TR_marker)
```

The input arguments are given in the example workspace. To use the adaptive_weighting_matrix function you at least need to provide the number of scans and the size of the correction template (n_template). For more features, you should pass the sampling rate, ECG data, the output from the above function and the start sample of the first TR (artifactOnsets(1)) to the function. See default values and descriptions for further information on the input arguments. A possible usage might look like this:

```
[weighting_matrix,realignment_motion,ecg_volumes] = adaptive_weighting_matrix(scans, n_template, 'sfreq', sfreq, 'ECG', ECG, 'events', artifactOnsets, start', artifactOnsets(1))
```

Alternatively, with some of the values from the workspace:

```
[weighting_matrix,realignment_motion,ecg_volumes] = adaptive_weighting_matrix(420, 25, 'sfreq', 1000, 'ECG', ECG, 'events', artifactOnsets, 'start', artifactOnsets(1))
```

After TR timings were extracted, the weighting matrix has been built and the input data was baseline corrected, the actual correction on the raw EEG data can be applied:

```
EEGbase = baseline_correct(EEG, 1, TR, artifactOnsets, weighting_matrix, 1, 0, TR);
EEG_GA_corrected = correction_matrix(EEGbase, 1, weighting_matrix, artifactOnsets, 0, TR);
```

![](workflow.png)

### Running tests

```
under construction
```

## Contributing

1. Fork it (<https://github.com/MalteGueth/EEG_fMRI_tmaze/fork>)
2. Create your feature branch (`git checkout -b feature/`)
3. Commit your changes (`git commit -am `)
4. Push to the branch (`git push origin feature/`)
5. Create a new Pull Request

<!-- Markdown link & img dfn's -->
[bergen_toolbox]: https://github.com/jnvandermeer/BergenToolboxModified
[lap_page]: http://neurostimlab.com
