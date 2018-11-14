function [gradient_artifacts, detected_TR] = automatic_marker_detection(EEG, TR, channel)

% Check if the input is a valid eeglab data structure
if ~exist(EEG, 'variable')
	error('The specified EEG dataset does not exist. Please choose a valid eeglab structure.');
end

% Select the channel for gradient detection
channel_data = EEG.data(channel,:);
% Use differential of the selected channel
data_diff = diff(channel_data); 
% Note the size of the selected data
dims = size(channel_data);

% Plot the chosen channels differential
plot(data_diff), title(['Differential of data channel' num2str(channel)]);

% Get the length of a single artifact in points by multiplying 
% the respective sampling rates of the EEG and the fMRI data
window = TR*EEG.srate;

% A rough estimate like the one above can be misleading because of
% asynchronies in the scanner marker onset and drifts over time
% Hence, for the final duration value calculate the difference between
% the window with the lowest autocorrelation and the highest
% autocorrelation over the entire dataset
window_iter = find(en_autocorr(data_diff, window) > 0.95);
artifact_duration = max(window_iter)-min(window_iter); 

% Calculate the artifact amplitude threshold to be considered a gradient trigger value
% by using 50% of the maximal amplitude of the differential
threshold = ceil(max(data_diff)*0.5);

% Apply threshold detection

% Set the initial value for the artifact counter to and detected 
% artifact positons to 1
time=1;
artifact_onset=1;
gradient_artifacts=[];
% Loop through the time points of the data from beginning to end
while time < dims(2)
    % If the differential exceeds the threshold...
    if data_diff(time) > lim_threshold
        % ... note the position of the artifact
        gradient_artifacts(artifact_onset)=time;
        % Move on in the time scale by the length of the current artifact
        time=time+artifact_duration;
        % Move to the next column in fMRI scans
        artifact_onset=artifact_onset+1;
    else
        time = time+1;
    end
end

% For validation purposes, the calculated TR between artifacts can be returned
% by taking the difference between the first two artifact timings and converting 
% by it converting into seconds
detected_TR = (gradient_artifacts(2)-gradient_artifacts(1))/EEG.srate*1000;

end