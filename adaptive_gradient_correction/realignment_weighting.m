function [weighting_matrix, realginment_motion] = realignment_weighting(scans,n_template,rp_file,varargin)

checkNum = @(x) isnumeric(x) && isscalar(x);

p=inputParser;
p.addParameter('threshold', 0.5, checkNum);
p.parse(varargin{:});

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

else
    % Show a warning if no value exceeded threshold and explain the
    % consequences
    warning('None of the provided realignment parameters exceed the given threshold. This will result in an unmodified correction window. If this is not wanted, consider setting a lower movement threshold and re-run this function.')
end
