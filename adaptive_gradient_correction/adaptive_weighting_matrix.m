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
            movements from influencing the correction.
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
        recording.
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
              'qrs'.
      
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
p.addParameter('threshold', [], checkNum);
p.addParameter('ECG', [], checkNum)
p.addParameter('start', [], checkNum)
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
    
    % Check if the provided realignment parameter file (rp file) exists
    if ~exist(rp_file, 'file')
        error('The given realignment parameter file does not exist. Please provide a correct file name.');
    end
    
    % Load the rp file
    motion_file = load(rp_file);
    
    % Calculate the movement magnitude or accelaration for translational
    % and rotational movements
    translational = realign_euclid(diff(motion_file(:,1:3)));
    rotational = realign_euclid(diff(motion_file(:,4:6)))*180/pi;

    % Threshold the results of the previous step to the requested value and
    % combine both movement values
    thresholded_trans = translational.*(translational>threshold);
    thresholded_rot = rotational.*(rotational>threshold);
    realignment_motion = thresholded_trans + thresholded_rot;
    
    % To prevent possible errors, adjust the length of the motion vector if
    % there is a discrapency between the length of the original file and
    % the vector
    realignment_motion = [zeros(1,length(motion_file)-length(realignment_motion)) realignment_motion];
    
    % Get the total number of scans listed in the realignment_motion vector
    n_data=length(realignment_motion);

    % Compare that length to the amount of scans passed to the function to
    % account for dummy scans
    diff_n=scans-n_data;
    % Adjust the length of the movement matrix in accordance to the
    % difference
    realignment_motion =[zeros(1,diff_n),realignment_motion];
    
    % Perform the following loop only if there is a rp larger than 0 (above
    % threshold)
    if max(realignment_motion) > 0
        
        % Set up variables and the moving window as shown above for the
        % linear weighting
        window=zeros(scans,n_template);
        lin_distance=zeros(1,scans);
        for half_window=1:scans

            lin_distance(1:half_window)=half_window:-1:1;
            lin_distance(half_window+1:end)=2:1:scans-half_window+1;

            % Create a scale for motion artifacts detected through the
            % ratio of artifact templates and the minimum movement artifact
            % (effect of the smallest movement over the number of artifacts
            % / over time)
            motion_scaling = n_template/min(realignment_motion(realignment_motion>0));
            % Add the (linear) distance to the cumulative sum of motion
            % artifacts
            lin_distance = lin_distance + motion_scaling * cumsum([-realignment_motion(1:half_window) +realignment_motion(half_window+1:end)]);
            lin_distance(realignment_motion>0)= NaN;
            
            % Again, as above for the linear weights...
            [~,order]=sort(lin_distance);
            window(half_window,:)=order(1:n_template);
        end
        
        weighting_matrix=zeros(scans);
        for artifact=1:scans
            weighting_matrix(artifact,window(artifact,:))=1;
        end
        
        % For checking results, plot the weighting matrix (scans-by-scans)
        % and mind the mid diagonal in relation to accelaration values 
        % exceeding threshold in the above matrix plotting the motion
        % vector
        figure(1)
        subplot(3,1,1);
        plot(realignment_motion,'k')
        xlim([0 scans])
        subplot(3,1,[2,3]);
        imagesc(weighting_matrix)
        colormap(gray)

    else
        % Show a warning if no value exceeded threshold and explain the
        % consequences
        warning('None of the provided realignment parameters exceed the given threshold. This will result in an unmodified correction window. If this is not wanted, consider setting a lower movement threshold and re-run this function.')
    end
    
% If enough arguments for an ECG-informed average artifact 
% subtraction are passed, add another modification of the weighting
% matrix
elseif ~isempty(p.Results.ECG)
    
    % Create a modifiable weighting matrix for the total number of scans
    % with ones for each scan as default
    switch (p.Results.heart_and_motion)
        case false
                weighting_matrix = linear_weighting(scans,n_template);
        case true
            % Check if the provided realignment parameter file (rp file) exists
            if ~exist(rp_file, 'file')
                error('The given realignment parameter file does not exist. Please provide a correct file name.');
            end

            % Load the rp file
            motion_file = load(rp_file);

            % Calculate the movement magnitude or accelaration for translational
            % and rotational movements
            translational = realign_euclid(diff(motion_file(:,1:3)));
            rotational = realign_euclid(diff(motion_file(:,4:6)))*180/pi;

            % Threshold the results of the previous step to the requested value and
            % combine both movement values
            thresholded_trans = translational.*(translational>threshold);
            thresholded_rot = rotational.*(rotational>threshold);
            realignment_motion = thresholded_trans + thresholded_rot;

            % To prevent possible errors, adjust the length of the motion vector if
            % there is a discrapency between the length of the original file and
            % the vector
            realignment_motion = [zeros(1,length(motion_file)-length(realignment_motion)) realignment_motion];

            % Get the total number of scans listed in the realignment_motion vector
            n_data=length(realignment_motion);

            % Compare that length to the amount of scans passed to the function to
            % account for dummy scans
            diff_n=scans-n_data;
            % Adjust the length of the movement matrix in accordance to the
            % difference
            realignment_motion =[zeros(1,diff_n),realignment_motion];

            % Perform the following loop only if there is a rp larger than 0 (above
            % threshold)
            if max(realignment_motion) > 0

                % Set up variables and the moving window as shown above for the
                % linear weighting
                window=zeros(scans,n_template);
                lin_distance=zeros(1,scans);
                for half_window=1:scans

                    lin_distance(1:half_window)=half_window:-1:1;
                    lin_distance(half_window+1:end)=2:1:scans-half_window+1;

                    % Create a scale for motion artifacts detected through the
                    % ratio of artifact templates and the minimum movement artifact
                    % (effect of the smallest movement over the number of artifacts
                    % / over time)
                    motion_scaling = n_template/min(realignment_motion(realignment_motion>0));
                    % Add the (linear) distance to the cumulative sum of motion
                    % artifacts
                    lin_distance = lin_distance + motion_scaling * cumsum([-realignment_motion(1:half_window) +realignment_motion(half_window+1:end)]);
                    lin_distance(realignment_motion>0)= NaN;

                    % Again, as above for the linear weights...
                    [~,order]=sort(lin_distance);
                    window(half_window,:)=order(1:n_template);
                end

                weighting_matrix=zeros(scans);
                for artifact=1:scans
                    weighting_matrix(artifact,window(artifact,:))=1;
                end
             end
    end
        
    
    % Baseline correct the ECG data, before subtracting the average
    % artifact
    ECGbase = BaselineCorrect(ECG, 1, TR, artifactOnsets, weighting_matrix, 1, 0, TR);

    % Apply a sliding correction window built from the weighting matrix to
    % the ECG data
    ECGcorrected = correction_matrix(ECGbase,1,weighting_matrix,artifactOnsets,0,TR);
    
    % Use the information about R peaks to identify the Q and S samples and
    % to epoch the data around the R peak
    switch (p.Results.ecg_feature)
        case 'r_peak'
            % Use peak detection to identify R peaks in the ECG and get
            % indices representing samples at which a peak was reached (see
            % qrs_detect)
            [R_peaks,~,~,~,~,~] = qrs_detect(ECGcorrected,sfreq,artifactOnsets(1));
            
            % Get the amplitude values and search for outlier R peaks
            Ramp = ECGcorrected(R_peaks);
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
                % Modify the weighting matrix previously used on the ECG
                weighting_matrix(TR_outliers) = NaN;
            end
        case 'qrs'
            % ... in addition to 'r_peak' get the Q and S timings
            [R_peaks,R_segments,~,q,s,~] = qrs_detect(ECGcorrected,sfreq);
            
            % To derive a measure indicating conspicuous ECG segments, calculate
            % the variance for each segment as well as the average variance
            % centered around the qrs complex
            smaller_segments = R_segments(:,100:300);
            ecg_variance = var(smaller_segments,0,2);
            ecg_outliers = isoutlier(ecg_variance,'mean');
            
        case 'pq_time'
        case 'qt_interval'
        case 'elevated_st'
    end

end
