%{
function marker_detection
This function detects a specified marker for the TR of an MR sequence 
in an event channel.

REQUIRED INPUTS
events - A cell array with event labels in the first and respective 
sample points in the seconds column
TR_trigger - The name of the TR marker as a string.

OUTPUT
gradient_artifacts - The onsets in sample points for all gradient 
artifacts indicated by the TR markers.
%}

function [gradient_artifacts] = marker_detection(events, TR_trigger)

artifact_onsets = strcmp(events(1,:), TR_trigger);
gradient_artifacts = events(2,artifact_onsets);
