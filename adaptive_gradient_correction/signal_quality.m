function [SNR, powerRatio] = signal_quality(ERP_GAcorr,ERPuncorr,channel,PowerEEG,PowerEEGfMRI)

% Compute a signal to noise ratio (SNR) for gradient corrected data and not
% corrected data unaffected by gradient artifacts. The SNR is calculated as
% a correlation of the two single trial ERP signals for a specific channel.
% In addition, if an array of spectral power recorded just with EEG and
% EEG-fMRI is passed, the ratio of EEG to EEG-fMRI is computed to assess
% remaining signal during simultaneous recordings.
% The ERP arrays should be three dimensional with channels x epochs x
% samples. Averaged power should be passed in the shape of channels x
% averaged samples.

SNR = (cov(ERP_GAcorr(channel,:,:),ERPuncorr(channel,:,:))/var(ERP_GAcorr(channel,:,:))*var(ERPuncorr(channel,:,:))^2;

if nargin == 5
    powerRatio = PowerEEG(channel,:)/PowerEEGfMRI(channel,:);
end
