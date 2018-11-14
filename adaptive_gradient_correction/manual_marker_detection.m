function [gradient_artifacts] = manual_marker_detection(EEG, TR_trigger)

artifact_onsets = strcmp(EEG.event(event).type, TR_trigger);
gradient_artifacts(artifact_onsets)=EEG.event(artifact_onsets).latency;

end