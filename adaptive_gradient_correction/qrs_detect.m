%{
function qrs_detect
This function identifies the QRS component and returns indices/samples for
each of the peaks. In addition, it performs a segmentation on continuous
ECG signals and returns them as an array (segment-by-sample points). If the
segmentation of heart beats is successful, the average heart beat is
plotted.
The basic procedures for peak detection are based on norms and workflows as
implemented in mne python: https://github.com/mne-tools/mne-python .
REQUIRED INPUTS
ECG - An ECG channel provided as a row vector of samples (in Microvolt).
sfreq - The sampling rate in Hz.
start - The number of sample points recorded before the onset of the fMRI
        recording.
OPTIONAL INPUTS
threshold - A factor for determining a threshold for detection of R peaks.
            Inputs can be integers or 'auto'. The latter results in an
            iterative estimation of the presumably most appropriate
            threshold. Default is set to 0.6.
l_freq - The high pass filter cutoff for bandpass filtering the ECG signal.
         The default value is set to 5 Hz.
h_freq - The low pass filter cutoff for bandpass filtering the ECG signal.
         The default value is set to 30 Hz.
      
OUTPUT
R_peaks - A vector of samples/indices for each R peak over the continuous
          ECG signal.
R_segments - An array of heart beat epochs by sampling points. Each epoch
             has a duration of a second and is centered around the R peak.
p,q,s,t - A vector analogous to the R_peaks output, indicating the peak of
          the other heart beat components. 
ECGfilt - The cleaned ECG signal used for detection.
%}

function [R_peaks,R_segments,p,q,s,t,ECGfilt] = qrs_detect(ECG, sfreq, start, varargin)

validString = 'auto';
checkString = @(x) any(validatestring(x,validString));
checkNum = @(x) isnumeric(x) && isscalar(x);

p=inputParser;
p.addParameter('threshold', 0.6, checkString);
p.addParameter('l_freq', 5, checkNum)
p.addParameter('h_freq', 30, checkNum)
p.parse(varargin{:});

% Calculate the size of the window for peak detection                            
window_length = (60*sfreq)/120;
% Bandpass filter the ECG before applying detection
ECGabs = abs(bandpass(ECG(start:end), [p.Results.l_freq p.Results.h_freq], sfreq));
% Get the total number of samples in the ECG
ECGpnts = length(ECGabs);

% In order to adjust to an individual ECG recording,
% average over the peaks of the first ten seconds 
% and derive an approximation of the amplitude size
maxAmp = zeros(10,1);
for beat = 1:length(maxAmp)
    if beat==1
        maxAmp(beat) = max(ECGabs(1:sfreq));
    else
        maxAmp(beat) = max(ECGabs(sfreq*(beat-1):sfreq*beat));
    end
end
initial_max = mean(maxAmp);

% If automatic detection of a suitable threshold is needed,
% create a set of potential factors for calculating amplitude thresholds 
% to iterate in the for loop below
if strcmp(p.Results.threshold,'auto')
    thresholds = 0.3:0.05:1.1;
else
    % ... if a threshold is specified, use it as the only iteration
    thresholds = p.Results.threshold;
end

% Create an empty array for peak timings
R_peaks = [];
% Loop over each threshold value
for threshIter = 1:length(thresholds)
    % Create a threshold from the approximated amplitude
    % and the factor for thresholding
    currentThreshold = initial_max*thresholds(threshIter);
    % Create empty arrays for each threshold iteration
    Ncrossings = [];
    samples = [];
    rms = [];
    % Start with the first sample for the following while loop
    currentSample = 1;
    % Move over each sample as long as the window size plus
    % the current sample does not exceed the total number of ECG samples
    while currentSample < (ECGpnts - window_length)
        % Create the window starting from the current sample
        window = ECGabs(currentSample:currentSample+window_length);
        if window(1) > currentThreshold
            % Find the index (sample) of the maximum value within the
            % window
            [~,peak_sample] = max(window);
            % Note the sample of the peak by appending it to the respective
            % array
            samples = [samples (currentSample+peak_sample)];
            nx = sum(diff(((window > currentThreshold)==1)));
            Ncrossings = [Ncrossings nx];
            rms = [rms sqrt(sumsqr(window)/length(window(:)))];
            currentSample = currentSample + window_length;
        else
            currentSample = currentSample + 1;
        end
    end
    if isempty(rms)
        rms = [rms 0];
        samples = [samples 0];
    end
    rms_mean = mean(rms);
    rms_std = std(rms);
    rms_thresh = rms_mean + (rms_std*2.5);
    thresholdedRMS = find(rms < rms_thresh);
    validCross = Ncrossings(thresholdedRMS);
    cleanEve = samples(thresholdedRMS(validCross < 3));
    R_peaks = [R_peaks cleanEve];
end

% If more than just the R peaks are requested, use the information about R
% peaks to identify the other components of a heart beat segment
if nargout > 1 
    
    % Use half of the sampling rate as a window to look before and after
    % the R peak (so in total one second epochs) for P, Q, S and T
    pnts_step = sfreq/2;
    % Further, clean the ECG by filtering (no absolute values as above)
    ECGfilt = bandpass(ECG(start:end), [p.Results.l_freq p.Results.h_freq], sfreq);
    % Build the necessary arrays to store the data
    R_segments = zeros(length(R_peaks),(pnts_step*2)+1);
    s = zeros(1,length(R_peaks));
    q = zeros(1,length(R_peaks));
    t = zeros(1,length(R_peaks));
    p = zeros(1,length(R_peaks));
    
    % Loop through all identified R peaks (skip the first and the last)
    for peak = 1:length(R_peaks)
        if R_peaks(peak)-pnts_step > 0 && R_peaks(peak)+pnts_step < ECGpnts
            % Extract data points around each R peak from the ECG signal
            % (double of the above window's size)
            R_segments(peak,:) = ECGfilt(R_peaks(peak)-pnts_step:R_peaks(peak)+pnts_step);
            % Search before (P,Q) and after (S,T) the R peak for the next
            % largest negative and positive peaks
            ECG_inverted = -ECGfilt(R_peaks(peak):R_peaks(peak)+(pnts_step/5));
            [~,s(peak)] = max(ECG_inverted);
            % Adjust the index for the smaller value of the window for peak
            % detection
            s(peak) = s(peak)+R_peaks(peak);
            % Now the same for the other components
            % Search for T approx. 500ms after S
            ECG_inverted = -ECGfilt(s(peak):s(peak)+pnts_step);
            [~,t(peak)] = max(ECG_inverted);
            t(peak) = t(peak)+s(peak);
            % Search for Q approx. 100ms before R
            ECG_inverted = -ECGfilt(R_peaks(peak)-(pnts_step/5):R_peaks(peak));
            [~,q(peak)] = max(ECG_inverted);
            q(peak) = q(peak)+(R_peaks(peak)-(pnts_step/5));
            % Search for P approx. 350ms before Q
            ECGsmall = ECGfilt(q(peak)-(pnts_step*0.7):q(peak));
            [~,p(peak)] = max(ECGsmall);
            p(peak) = p(peak)+(q(peak)-(pnts_step*0.7));
        end
    end
    
    % In case there are not enough samples before the first heart
    % beat to go back half a second and the index switches to two,
    % delete the first empty row of zeros
    if ~any(R_segments(1), 2)
        warning('There are not enough samples before the first R peak. This first segment will be skipped. Include more sample points if this should be avoided.')
        R_segments(1,:) = [];
        p(1) = [];
        q(1) = [];
        s(1) = [];
        t(1) = [];
    end
    
    % Calculate the average waveform and plot it
    mean_heartBeat=mean(R_segments,1)/1000;
    [~,Raverage] = max(mean_heartBeat);

    figure(2)
    hold on
    plot(mean_heartBeat)
    plot(Raverage,mean_heartBeat(Raverage),'rv','MarkerFaceColor','r')
    axis([0 (pnts_step*2) min(mean_heartBeat)-0.1 max(mean_heartBeat)+0.1])
    title('Averge heart beat epoch')
    legend('ECG','R peak')
    xlabel('Sample points')
    ylabel('Voltage (mV)')
end
