function [ecg_outliers] = find_ecg_outliers(ecg_feature,scans,sfreq,TR)

ecg_outliers = zeros(1,scans);

% Find indices of the TR intervals affected by the outlier ecg 
% events
ECG_scans = find(ecg_feature==1);
% Pick the TR interval the outlier occured in by first 
% aligning TR and sample points (TR = (samples/sfreq)/(TR/1000))
ECG_scans = ceil((ECG_scans/sfreq)/(TR/1000));
% In case there are outliers beyond the total number of
% scans, delete them
ECG_scans(ECG_scans>scans) = [];

% Mark the affected TR interval
ecg_outliers(unique(ECG_scans)) = 1;
