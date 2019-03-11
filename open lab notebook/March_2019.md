### Mar. 4th - Mar. 10th
* On Monday, I tried to retrace what I had done last December for the time frequency analysis of the first two EEG-fMRI pilot data sets. The matlab script ran fine and I could plot results. However, the effects were weaker and generally did not correspond to what I had previously found with my python script. Hence, I tried to find mistakes, but I was unsuccessful.

  * I checked all nested loops for mixups, the shapes of the in-/output files, the plotting sections and the how the results were stored - none seemed faulty.
  
  * In the end, I left the script as it was and ran it again to see if I had used the correct files.
  
* After hearing the introduction to the Amarel cluster and receiving access, I practiced managing it a little by moving data around and storing the TBS CT structural data on my home directory.

* Also, I backed up all structural and functional MRI data on a hard drive and my desktop computer in baker lab. The EEG data was already backed up there. 

* Tuesday I sat down with Travis and worked through the script and discussed the results. While on that note, I walked him through the entire EEG preprocessing (see jupyter notebooks). We noticed a couple of sources for errors and aspects in the preprocessing that should be revised.

  * Points for revision:
    * In the experiment programming: counterbalance the valence of fruit symbols for feedback
    * Add a comparison of the N170 for maze vs nomaze trials to the epoching/evoked notebook
    * Set the bandpass filter before epoching to 1 - 60 and for after to 1 - 20
    * Focus on the M1 and M2 equivalents for the mastoid reference 
    * Try to fill in more gaps in the jupyter notebook examples (i.e. no downsampling for ICA and eye component example
    * Be sure to correct the selection of electrodes for pooling
    * Correct the event timings for the prerelease delay
    * Create separate epochs for slow and too fast responses
    * Remove the difference wave from the example for the N170
    * Make sure not to produce double outputs in the notebooks
    
  * Points for time frequency:
    * The baseline was still set without taking the prerelease delay into account, so it was including a very early window
    * Include alley specific ERPs in the analysis
    * Check the export script in python again and redo the .mat export
    * When rerunning the time frequency analysis, focus on E170 and E15 first - no need to redo all 256 channels
    * Check the .fif files used fot the export

* For the rest of the week I worked on a presentation of the study (pilot results) for the Baker lab meeting on Friday 8th

  * Since it took me a little longer to implement a lot of the above changes in the pipeline, I decided to go for the existing results which I can explain and critique confidently. Thus, I included single subject ERPs, time frequency results, fMRI contrasts (both for feedback and alleys) and an MRI-informed source estimation for the N170.

  * I started revising the preprocessing jupyter notebooks, but ended up waiting for feedback from the presentation on Friday.

  * The presentation went well. For feedback I noted the following points:
    * Compare the implemented ICA approach with PCA and see if they can be combined without overcorrecting
    * Include occular correction component mapping into the respective notebook
    * See how much of the signal would get marked with another artifact detection after the final ICA correction
    * Remember to include both whole brain and ROI contrasts for not just spatial navigation and feedback clusters but also both alleys
    * Try to find a way to have source localization be informed by functional activation clusters (do literature research on that subject)
    * The idea to include links/qr codes on slides for specific analyses (leading to the corresponding jn) was well received
    * The intro went over well, but try to paraphrase less (more my own criticism)

* The rest of the week I spent studying for the upcoming midterms exam.
