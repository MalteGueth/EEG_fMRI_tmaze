function [ecg_events,hrate] = qrs_detect(ECG, sfreq, threshold, Nstd, l_freq, h_freq)
                                 
window_length = round((60*sfreq)/120);
ECGfilt = abs(bandpass(ECG, [l_freq h_freq], sfreq));
ECGpnts = length(ECGfilt);

maxAmp = zeros(10,1);
for beat = 1:length(maxAmp)
    if beat==1
        maxAmp(beat) = max(ECGfilt(1:sfreq));
    else
        maxAmp(beat) = max(ECGfilt(sfreq*(beat-1):sfreq*beat));
    end
end
initial_max = mean(maxAmp);

if strcmp(threshold,'auto')
    thresholds = 0.3:0.05:1.1;
else
    thresholds = threshold;
end

ecg_events = [];
for threshIter = 1:length(thresholds)
    thresh1 = initial_max*thresholds(threshIter);
    Ncrossings = [];
    time = [];
    rms = [];
    currenSample = 1;
    while currenSample < (ECGpnts - window_length)
        window = ECGfilt(currenSample:currenSample+window_length);
        if window(1) > thresh1
            [~,max_time] = max(window);
            time = [time (currenSample + max_time)];
            nx = sum(diff(((window > thresh1) == 1)));
            Ncrossings = [Ncrossings nx];
            rms = [rms sqrt(sumsqr(window)/length(window(:)))];
            currenSample = currenSample + window_length;
        else
            currenSample = currenSample + 1;
        end
    end
    if isempty(rms)
        rms = [rms 0];
        time = [time 0];
    end
    rms_mean = mean(rms);
    rms_std = std(rms);
    rms_thresh = rms_mean + (rms_std*Nstd);
    thresholdedRMS = find(rms < rms_thresh);
    validCross = Ncrossings(thresholdedRMS);
    cleanEve = time(thresholdedRMS(validCross < 3));
    ecg_events = [ecg_events cleanEve];
end
