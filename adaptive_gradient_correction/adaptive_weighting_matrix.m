%{
function adaptive_weighting_matrix
This function and listed helper functions are all adapted from the analyses
presented in Allen, Josephs, & Turner (2000) as well as Moosmann,
Schoenfelder, Specht Scheeringa, Nordby, & Hudgahl (2009). All original
functions are copyrighted by the Bergen fMRI group and can be found on
their github repository:
https://github.com/jnvandermeer/BergenToolboxModified.
This function creates the weighting matrix for an adaptive ECG- and 
realignment-informed average artifact subtraction appraoch to correct
gradient artifacts from electrophysiological data which was recorded
inside the MRI environment. 
The returned weighting matrix provides the basis for a sliding correction
window that can be applied to continuous EEG and ECG data.

REQUIRED INPUTS
scans - A single integer representing total number of TR/acquired 
        functional images.
n_template - The number of artifacts that make up the window length.

OPTIONAL INPUTS
rp_file - If a realignment parameter-informed average artifact subtraction
          (see Moosmann et al., 2009) is desired, assigning special weights 
          to artifacts distorted by significant head movements (i.e., 
          translation, rotation), a text file of vectors can be passed to 
          the function. The file should contain the x,y and z coordinates 
          obtained during the realignment of the simultaneously recorded 
          functional images. The rows of the file should be the number of 
          total scans.
threshold - If an rp_file was passed, this argument sets the threshold for
            significant movements. The threshold should a single integer 
            indicating the minimum movement accelaration 
            (see realign_euclid.m) for biasing the weighting matrix. This 
            is recommended to avoid slow, probably none harmful head 
            movements from influencing the correction. The default value
            is set to 0.5.
ECG - If on top of the realignment parameter-informed average 
      artifact subtraction, an ECG-based correction is requested, 
      an ECG channel can be specified. Both a row index of an ECG 
      channel wihtin a matrix of voltages for different channels 
      over time or a vector of a single ECG channel (also voltage 
      over time) can be passed to the function.
      This new approach is designed to take distortions of the 
      gradient artifact by ballistocardiac artifacts into account. 
      When an above threshold value for features of the heart beat cycle 
      for a single artifact is detected, the weighting matrix returned 
      by this function is adapted. Modifications of the weighting 
      matrix are performed analogous to the adaptation to motion 
      artifacts. 
      The parameter indicating outlier heart beats can be chosen by
      the ecg_feature argument. The default is set to 'qrs'.
start - The number of sample points recorded before the onset of the fMRI
        recording. The default is set to the first sampling point.
sfreq - The sampling rate in Hz.
heart_and_motion - A logical indicating whether a combination of
                   realignment- and ECG-informed artifact correction shall
                   be performed. Default is set to true. If set to false,
                   only heart beat events will be used to modify the
                   weighting matrix. If both is requested, note that the
                   necessary arguments for a realignment-informed correction
                   have to be passed as well.
ecg_feature - String values correspond to the ECG feature used to identify
              outlier artifact intervals. Valid inputs are 'r_peak', 'qrs', 
              'pq_time', 'qt_interval' and 'elevated_st'. Default is set to
              'qrs' for amplitude of R peaks, variance of the QRS complex,
              PQ intervals larger than 200ms, duration of the QT interval,
              and increases in the average amplitude of the ST component
              respectively.
      
OUTPUT
weighting_matrix - An N-by-N matrix containing the weights for building a
                   correction template to be applied to the continuous EEG 
                   and ECG signal.
realignment_motion - A row vector of movement accelartion values (euclidian
                     vector magnitude) with the same length as the number 
                     of artifacts. Non-zero values indicate which artifacts
                     were identified as above-threshold for the correction.
ecg_outliers - A row vector of R peaks with a value for each heart beat. 
               Here, non-zero cell values correspond to above-threshold
               ECG feature values.
              
Helper and related functions:
linear_weighting.m - Creates a square weighting matrix (scans-by-scans)
                     with equal weights for each scan interval.
realignment_weighting.m - Creates a square weighting matrix (scans-by-scans)
                          modfified depending on large movements.
baseline_correct.m - Performs a baseline correction on each artifact interval
                     according to a requested method.
marker_detection.m - Identifies all artifact intervals over the EEG 
                     signal based on TR markers set during the 
                     concurrent recording.
realign_euclid.m - Uses euclidian norm to convert motion vectors into 
                   euclidian distance (or vector magnitude).
correction_matrix.m - Applies the weighting matrix to a sliding window on 
                      the continuous EEG and ECG data.
qrs_detect.m - Identifies components of heart beat events and returns 
               latencies (in points) of the peaks of the qrs wave.
%}

function [weighting_matrix,realignment_motion,ecg_volumes] = adaptive_weighting_matrix(scans,n_template,varargin)

validString = {'r_peak', 'qrs', 'pq_time', 'qt_interval', 'elevated_st'};
checkString = @(x) any(validatestring(x,validString));
checkNum = @(x) isnumeric(x) && isscalar(x);

p=inputParser;
p.addParameter('rp_file', char.empty(0,0), @ischar);
p.addParameter('threshold', 0.5, checkNum);
p.addParameter('ECG', [], checkNum)
p.addParameter('events', [])
p.addParameter('start', 1, checkNum)
p.addParameter('sfreq', [], checkNum)
p.addParameter('heart_and_motion', true, @islogical)
p.addParameter('ecg_feature', 'qrs', checkString)
p.parse(varargin{:});

% If too few input arguments are provided, give the following error
% message...
if nargin < 2
    error('Please provide at least the total number of scans as well as the number of artifacts constituting the correction template for a linear correction window.')
elseif nargin == 2
    
    % Create a modifiable weighting matrix for the total number of scans
    % with ones for each scan as default
    weighting_matrix = linear_weighting(scans,n_template);
    
% If enough arguments for a realignment parameter-informed average artifact 
% subtraction are passed, switch from a linear weighting matrix to a
% motion parameter-informed one.
elseif ~isempty(p.Results.rp_file)
    
    % Create a weighting matrix and modify it in accordance
    % to provided motion data
    [weighting_matrix, realginment_motion] = realignment_weighting(scans,n_template,rp_file,threshold);
    
% If input arguments for an ECG-informed average artifact 
% subtraction are passed, add another modification of the weighting
% matrix
elseif ~isempty(p.Results.ECG)
    
    % Create a modifiable weighting matrix for the total number of scans
    % with a realignment-informed correction as default
    switch (p.Results.heart_and_motion)
        case false
                weighting_matrix = linear_weighting(scans,n_template);
        case true
                [weighting_matrix, realginment_motion] = realignment_weighting(scans,n_template,rp_file,threshold);
    end
        
    
    % Baseline correct the ECG data, before subtracting the average
    % artifact
    ECGbase = baseline_correct(ECG, 1, TR, p.Results.events, weighting_matrix, 1, 0, TR);

    % Apply a sliding correction window built from the weighting matrix to
    % the ECG data
    ECGcorrected = correction_matrix(ECGbase,1,weighting_matrix,p.Results.events,0,TR);
    
    % Use the information about R peaks to identify the Q and S samples and
    % to epoch the data around the R peak
    switch (p.Results.ecg_feature)
        case 'r_peak'

            % Use peak detection to identify R peaks in the ECG and get
            % indices representing samples at which a peak was reached (see
            % qrs_detect)
            [R_peaks,~,~,~,~,~,ECGfilt] = qrs_detect(ECGcorrected,sfreq,p.Results.events(1));
            
            % Get the amplitude values and search for outlier R peaks
            Ramp = ECGfilt(R_peaks);
            ecg_outliers = isoutlier(Ramp,'mean');
            
            % Check if there are any outliers at all
            if isempty(ecg_outliers)
                warning('None of the R peaks exceed the outlier threshold. This will result in an unmodified correction window. If this is not wanted, consider picking a different ECG feature.')
            % Otherwise, look for the TR intervals affected by the outliers
            else
                % Find outlier indices
                TR_outliers = ecg_outliers==1;
                % Pick the TR interval the outlier occured in by first 
                % aligning TR and sample points (TR = (samples/sfreq)/TR)
                TR_outliers = ceil((TR_outliers/sfreq)/TR);
                % In case there are outliers beyond the total number of
                % scans, delete them
                TR_outliers(TR_outliers>scans) = [];
                % Modify the weighting matrix previously used on the ECG
                weighting_matrix(TR_outliers) = NaN;
            end
        case 'qrs'

            % ... in addition to the R peaks, get the Q and S timings
            [~,~,~,q,s,~,ECGfilt] = qrs_detect(ECGcorrected,sfreq);
            
            % Get the qrs variance
            qrs = zeros(1,length(q));
            for beat = length(q)
                qrs(beat) = ECGfilt(q(beat):s(beat));
            end
            qrs_variance = var(qrs,0,2);
            ecg_outliers = isoutlier(qrs_variance,'mean');

            if isempty(ecg_outliers)
                warning('None of the QRS variances exceed the outlier threshold. This will result in an unmodified correction window. If this is not wanted, consider picking a different ECG feature.')
            else
                TR_outliers = ecg_outliers==1;
                TR_outliers = ceil((TR_outliers/sfreq)/TR);
                TR_outliers(TR_outliers>scans) = [];
                weighting_matrix(TR_outliers) = NaN;
            end
            
        case 'pq_time'

             % ... get the P and Q timings
            [~,~,p,q,~,~,ECGfilt] = qrs_detect(ECGcorrected,sfreq);
            
            % Get the PQ interval
            pq_time = zeros(1,length(p));
            for beat = length(p)
                pq_time(beat) = length(ECGfilt(p(beat):q(beat)));
            end
            % Find the PQ components over 200ms        
            ecg_outliers = pq_time(pq_time>=(sfreq/5));

            if isempty(ecg_outliers)
                warning('None of the PQ intervals exceed 200ms. This will result in an unmodified correction window. If this is not wanted, consider picking a different ECG feature.')
            else
                TR_outliers = ecg_outliers==1;
                TR_outliers = ceil((TR_outliers/sfreq)/TR);
                TR_outliers(TR_outliers>scans) = [];
                weighting_matrix(TR_outliers) = NaN;
            end
        case 'qt_interval'

             % ... get the Q and T timings
            [~,~,~,q,~,t,ECGfilt] = qrs_detect(ECGcorrected,sfreq);
            
            % Get the QT interval
            qt_interval = zeros(1,length(q));
            for beat = length(p)
                qt_interval(beat) = length(ECGfilt(q(beat):t(beat)));
            end
            % Find outlier QT intervals       
            ecg_outliers = isoutlier(qt_interval,'mean');

            if isempty(ecg_outliers)
                warning('None of the QT intervals exceed the outlier threshold. This will result in an unmodified correction window. If this is not wanted, consider picking a different ECG feature.')
            else
                TR_outliers = ecg_outliers==1;
                TR_outliers = ceil((TR_outliers/sfreq)/TR);
                TR_outliers(TR_outliers>scans) = [];
                weighting_matrix(TR_outliers) = NaN;
            end
        case 'elevated_st'

             % ... get the S and T timings
            [~,~,~,~,s,t,ECGfilt] = qrs_detect(ECGcorrected,sfreq);
            
            % Get the ST amplitude
            st_amp = zeros(1,length(q));
            for beat = length(s)
                st_amp(beat) = abs(ECGfilt(s(beat):t(beat)));
            end
            % Find outlier QT intervals       
            ecg_outliers = isoutlier(st_amp,'mean');

            if isempty(ecg_outliers)
                warning('None of the ST amplitudes exceed the outlier threshold. This will result in an unmodified correction window. If this is not wanted, consider picking a different ECG feature.')
            else
                TR_outliers = ecg_outliers==1;
                TR_outliers = ceil((TR_outliers/sfreq)/TR);
                TR_outliers(TR_outliers>scans) = [];
                weighting_matrix(TR_outliers) = NaN;
            end
    end

    if ~isempty(TR_outliers) && p.Results.heart_and_motion==true

        TRheart = zeros(1,scans);
        TRheart(TR_outliers) = 1;

        % Plot the combined ECG and realignment weighting matrix
        figure(3)
        subplot(3,1,1);
        hold on
        plotyy(realignment_motion,TRheart)
        xlim([0 scans])
        subplot(3,1,[2,3]);
        imagesc(weighting_matrix)

    elseif ~isempty(TR_outliers) && p.Results.heart_and_motion==false

        TRheart = zeros(1,scans);
        TRheart(TR_outliers) = 1;

        % Plot the ECG-informed weighting matrix
        figure(3)
        subplot(3,1,1);
        hold on
        plot(TRheart,'k')
        xlim([0 scans])
        subplot(3,1,[2,3]);
        imagesc(weighting_matrix)
    end
end
