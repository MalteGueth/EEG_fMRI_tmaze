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
            is set to 0.3 mm.
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
events - A set of artifact timings as given out by 'marker_detection.m'.
TR - The time of repetition utilized during functional image acquisition.
sfreq - The EEG/ECG sampling rate in Hz.
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
ecg_outliers - A row vector constructed analogously to 'realignment_motion'
               only for above threshold ECG events.
              
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
find_ecg_outliers - Based on a vector of logicals indicating above
                    threshold ECG parameter values across the continuous
                    signal, identify the affected TR intervals/scans.
%}

function [weighting_matrix,realignment_motion,ecg_outliers] = adaptive_weighting_matrix(scans,n_template,varargin)

realignment_motion = [];
ecg_outliers = [];

validString = {'r_peak', 'qrs', 'pq_time', 'qt_time', 'st_amp'};
checkString = @(x) any(validatestring(x,validString));
checkNum = @(x) isnumeric(x);

p=inputParser;
p.addParameter('rp_file', char.empty(0,0), @ischar);
p.addParameter('threshold', 0.3, checkNum);
p.addParameter('ECG', [], checkNum)
p.addParameter('TR', [], checkNum)
p.addParameter('events', [], checkNum)
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
elseif ~isempty(p.Results.rp_file) && isempty(p.Results.ECG)
    
    % Create a weighting matrix and modify it in accordance
    % to provided motion data
    threshold = p.Results.threshold;
    rp_file = p.Results.rp_file;
    [weighting_matrix, realignment_motion] = realignment_weighting(scans,n_template,rp_file,'threshold',threshold);
    
% If input arguments for an ECG-informed average artifact 
% subtraction are passed, add another modification of the weighting
% matrix
elseif ~isempty(p.Results.ECG)
    
    % Create a modifiable weighting matrix for the total number of scans
    % with a realignment-informed correction as default
    rp_file = p.Results.rp_file;
    threshold = p.Results.threshold;
    switch (p.Results.heart_and_motion)
        case false
                weighting_matrix = linear_weighting(scans,n_template);
        case true
                [weighting_matrix, realignment_motion] = realignment_weighting(scans,n_template,rp_file,'threshold',threshold);
    end
        
    % Baseline correct the ECG data, before subtracting the average
    % artifact
    TR = p.Results.TR;
    ECG = p.Results.ECG;
    artifactOnsets = p.Results.events;
    ECGbase = baseline_correct(ECG, 1, TR, artifactOnsets, weighting_matrix, 1, 0, TR);

    % Apply a sliding correction window built from the weighting matrix to
    % the ECG data
    ECGcorrected = correction_matrix(ECGbase,1,weighting_matrix,artifactOnsets,0,TR);
    
    % Use the information about R peaks to identify the Q and S samples and
    % to epoch the data around the R peak
    start = artifactOnsets(1);
    sfreq = p.Results.sfreq;
    switch (p.Results.ecg_feature)
        case 'r_peak'

            % Use peak detection to identify R peaks in the ECG and get
            % indices representing samples at which a peak was reached (see
            % qrs_detect)
            [R_peaks,~,~,~,~,~,ECGfilt] = qrs_detect(ECGcorrected,sfreq,start);
            
            % Get the amplitude values and 
            Ramp = zeros(1,length(ECGfilt));
            Ramp(R_peaks(:)) = ECGfilt(R_peaks(:));
            
            % Search for outlier peaks (3 standard deviations above the mean)
            Ramp_ind = Ramp>(3*std(Ramp(R_peaks(:)))+mean(Ramp(R_peaks(:))));
            % Get the outlier R peaks and their respective scan's indices            
            ecg_outliers = find_ecg_outliers(Ramp_ind,scans,sfreq,TR);
   
        case 'qrs'

            % ... in addition to the R peaks, get the Q and S timings
            [~,~,~,q,s,~,ECGfilt] = qrs_detect(ECGcorrected,sfreq,start);
            
            % Get the qrs variance
            qrs_variance = zeros(1,length(ECGfilt));
            for beat = 1:length(q)
                qrs_variance(q(beat)) = var(ECGfilt(q(beat):s(beat)),1);
            end
            
            % Get the outlier qrs complexes and their respective scan's
            % indices
            qrs_ind = qrs_variance>(3*std(qrs_variance(q(:)))+mean(qrs_variance(q(:))));
            ecg_outliers = find_ecg_outliers(qrs_ind,scans,sfreq,TR);
            
        case 'pq_time'

            % ... get the P and Q timings
            [~,~,p,q,~,~,ECGfilt] = qrs_detect(ECGcorrected,sfreq,start);
            
            % Get the PQ interval (approx. end of P to beginning of Q)
            pq_time = zeros(1,length(ECGfilt));
            for beat = 1:length(p)
                % Take about 100ms after P's peak and before Q's peak
                pq_time(p(beat)) = length(ECGfilt((p(beat)+(sfreq/10)):(q(beat)-(sfreq/10))));
            end
            
            % Find PQ durations over 200ms (normal PQ is about 120 ms)      
            pq_ind = pq_time>=(sfreq/5);
            ecg_outliers = find_ecg_outliers(pq_ind,scans,sfreq,TR);
            
        case 'qt_time'

            % ... get the Q and T timings
            [~,~,~,q,~,t,ECGfilt] = qrs_detect(ECGcorrected,sfreq,start);
            
            % Get the QT interval (approx. from the beginning of Q to the
            % end of T)
            qt_interval = zeros(1,length(ECGfilt));
            for beat = 1:length(q)
                % Take about 100ms after T's peak and before Q's peak
                qt_interval(q(beat)) = length(ECGfilt(q(beat)-(sfreq/10)):t(beat)+(sfreq/10));
            end
            
            % Find outlier QT intervals       
            qt_ind = qt_interval>(3*std(qt_interval(q(:)))+mean(qt_interval(q(:))));
            ecg_outliers = find_ecg_outliers(qt_ind,scans,sfreq,TR);

        case 'st_amp'

             % ... get the S and T timings
            [~,~,~,~,s,t,ECGfilt] = qrs_detect(ECGcorrected,sfreq,start);
            
            % Get the ST amplitude
            % The ST duration lasts approx. from the end of S to the
            % beginning of T
            st_amp = zeros(1,length(ECGfilt));
            for beat = 1:length(s)
                % Take about 100ms after S's peak and before T's peak
                st_amp(s(beat)) = mean(abs(ECGfilt(s(beat)+(sfreq/10)):t(beat)-(sfreq/10)));
            end
            
            % Find outlier ST amplitudes       
            st_ind = st_amp>(3*std(st_amp(s(:)))+mean(st_amp(s(:))));
            ecg_outliers = find_ecg_outliers(st_ind,scans,sfreq,TR);
    end
    
    feature = p.Results.ecg_feature;
    if isempty(ecg_outliers)
        warning(['None of heart beat events show an above threshold value for the chosen measure (' feature '). This will result in an unmodified correction window. If this is not wanted, consider picking a different ECG parameter.'])
    % Redo the weighting matrix with the newly found ecg outliers (see
    % linear_weighting.m and realignment_weighting.m)
    else
        window=zeros(scans,n_template);
        lin_distance=zeros(1,scans);

        switch (p.Results.heart_and_motion)
            case true
            
                for half_window=1:scans

                    lin_distance(1:half_window)=half_window:-1:1;
                    lin_distance(half_window+1:end)=2:1:scans-half_window+1;

                    motion_scaling = n_template/min(realignment_motion(realignment_motion>0));
                    lin_distance = lin_distance + motion_scaling * cumsum([-realignment_motion(1:half_window) +realignment_motion(half_window+1:end)]);
                    lin_distance(realignment_motion>0)= NaN;

                    % Insert the ECG-informed outliers
                    heart_scaling = n_template/min(ecg_outliers(ecg_outliers>0));
                    lin_distance = lin_distance + heart_scaling * cumsum([-ecg_outliers(1:half_window) +ecg_outliers(half_window+1:end)]);
                    lin_distance(ecg_outliers>0)=NaN;

                    [~,order]=sort(lin_distance);
                    window(half_window,:)=order(1:n_template);
                end

                weighting_matrix=zeros(scans);
                for artifact=1:scans
                    weighting_matrix(artifact,window(artifact,:))=1;
                end
            
            case true

                for half_window=1:scans

                    lin_distance(1:half_window)=half_window:-1:1;
                    lin_distance(half_window+1:end)=2:1:scans-half_window+1;

                    heart_scaling = n_template/min(ecg_outliers(ecg_outliers>0));
                    lin_distance = lin_distance + heart_scaling * cumsum([-ecg_outliers(1:half_window) +ecg_outliers(half_window+1:end)]);
                    lin_distance(ecg_outliers>0)=NaN;

                    [~,order]=sort(lin_distance);
                    window(half_window,:)=order(1:n_template);
                end

                weighting_matrix=zeros(scans);
                for artifact=1:scans
                    weighting_matrix(artifact,window(artifact,:))=1;
                end
         end
    end
    
    if ~isempty(ecg_outliers) && ~isempty(realignment_motion)

        % Plot the combined ECG and realignment weighting matrix
        figure(3)
        subplot(3,1,1);
        hold on
        plot(realignment_motion,'k')
        plot(ecg_outliers,'r')
        legend('Realignment',feature)
        title('Realignment- and ECG-informed weighting matrix')
        xlim([0 scans])
        subplot(3,1,[2,3]);
        imagesc(weighting_matrix)
        set(findall(gcf,'-property','FontSize'),'FontSize',10)
        set(findall(gcf,'-property','FontName'),'FontName','Arial')
        
    elseif ~isempty(ecg_outliers) && isempty(realignment_motion)

        % Plot the ECG-informed weighting matrix
        figure(3)
        subplot(3,1,1);
        hold on
        plot(ecg_outliers,'k')
        title('ECG-informed weighting matrix')
        xlim([0 scans])
        subplot(3,1,[2,3]);
        imagesc(weighting_matrix)
        set(findall(gcf,'-property','FontSize'),'FontSize',10)
        set(findall(gcf,'-property','FontName'),'FontName','Arial')
    end
end
