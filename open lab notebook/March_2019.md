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

### Mar. 11th - Mar. 17th
* I was preoccupied with studying for my midterms exam till Thursday 14th. The only notable developments regarding this study till then were a successful training session with my RA (for future data acquisitions with him) and some revisions of preprocessing jupyter notebooks (not updated yet in the repo folder)

  * Later that week, I continued the revision and read a couple of papers:
      * source estimation (for revising anatomically informed constraints): https://pdfs.semanticscholar.org/eaef/0dcaa875b151f0cbdd806abf39cc61d97b9a.pdf
      
      * memory, EEG-fMRI, single trial ERP analysis: https://pdfs.semanticscholar.org/eaef/0dcaa875b151f0cbdd806abf39cc61d97b9a.pdf
      
      * EEG-fMRI safety, temperature at 3T: https://journals.sagepub.com/doi/10.1177/0284185114536385
      
### Mar. 18th - Mar. 24th
* I discussed the problem of artifcats caused by vibrations induced by the scanner's helium pump with several people involved in the study or the administration of RUBIC (see https://pressrelease.brainproducts.com/vibration-artifacts-during-eeg-fmri/). For now, time is pressing and I need to continue with the data collection. Plus, previously collected data seemed interpretable. Hence, for now the curret situation has to suffice.

* I discussed final preparations for starting data collection next week with Travis and my RA.

* In the past week, I read the following papers related to the general topics of the study:

 * Methods paper on EEG-TMS-MRI: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3569123/
 
 * fMRI mental maze solving: https://www.karger.com/Article/PDF/95742?casa_token=z_lI7ONCi1gAAAAA:RxTuRIWUn2X4akvF1BF6NqZVsoSwczUbOXNECxCK7mbOybqKT0RGF0B9T9RansQ3YoC4LfPI
 
 * Theta-Alpha, HC-PFC, memory, EEG-fMRI : http://www.jneurosci.org/content/jneuro/36/12/3579.full.pdf

### Mar. 25th - Mar. 31st
* A big part of the last week was spent on getting all preparations for the coming experiments right, giving my RA his final training sessions, recruiting subjects, scheduling time slots in different labs/facilities, and putting together the final runsheet.

* On Thursday, we collected our first subject since the pilot runs. There were two major incididents relating to the E-prime experiment and Net Station:

  * At first, they failed to communicate properly, so that only MR triggers were recorded in the EEG file. After restarting the experiment and Net station, the issue was resolved.
 
  * The second failure occured right aftewards. Net Station froze up and we had to interrupt the data acquisition again.

* Taken together, the two malfunctions together with a long functional acquisition using the T-maze caused us to only acquire an anatomical T1 and functional data. Hence, we had to drop DTI and resting state. Furthermore, due to complications at the beginning of the experiment, we had to skip the acquisition of electrode positions using GPS. I asked the subject to come back for that later the next week, but those positions will not be as accurate, since the net fit will change.

* Regarding measures to prevent these malfunctions, I emailed an error report to a contact person at EGI and Travis shortened the paradigm.

* In order to prepare for this year's meeting of the Society for Psychophysiological Research, I wrote a draft for my poster abstract as well as submission to the Big Questions Sympoisum (subject 03: data integration) and sent it to Travis for review.

* In the past week, I read/re-read the following papers related to the general topics of the study:

  * Neural mechanisms of spatial navigation: http://www.jneurosci.org/content/jneuro/39/12/2301.full.pdf
  
  * Feature analysis for correlation studies of simultaneous EEG-fMRI data: a proof of concept for neurofeedback approaches: https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=7319287
