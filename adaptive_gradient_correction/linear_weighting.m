function weighting_matrix = linear_weighting(scans,n_template)

% Set up some pre-computational variables for the window size and a
% a linear distance vector
window=zeros(scans,n_template);
lin_distance=zeros(1,scans);

% Inititate sliding correction window around a central artifact point
for half_window=1:scans
    % In order to get all artifact samples, create the linear distance 
    %between the first and central data point ...
    lin_distance(1:half_window)=half_window:-1:1;
    % ... and now into the other direction between the halfed window size 
    % and the end of the sliding window
    lin_distance(half_window+1:end)=2:+1:scans-half_window+1;
    % Sort weights and samples by distance value ...
    [~,order]=sort(lin_distance);
    % ... and start with the smalest distance value
    window(half_window,:)=order(1:n_template);
end

% Create a modifiable weighting matrix for the total number of scans
% with ones for each scan as default
weighting_matrix=zeros(scans);
for artifact=1:scans
    weighting_matrix(artifact,window(artifact,:))=1;
end
