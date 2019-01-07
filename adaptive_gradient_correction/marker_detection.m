%{
function marker_detection

This function detects a specified marker for the TR of an MR sequence 
in an event channel.

REQUIRED INPUTS
events - A cell array with samples in the first and respective 
event labels in the second column
TR_trigger - The name of the TR marker as a string.

OUTPUT
artifactOnsets - The onsets in sample points for all gradient 
artifacts indicated by the TR markers.
%}

function [artifactOnsets] = marker_detection(events, TR_marker)

artifacts = strcmp([events{:,2}]', TR_marker);
artifactOnsets = [events{artifacts,1}]';
