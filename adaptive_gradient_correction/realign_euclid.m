function accel=realign_euclid(realignment_param)

% Create an array of zeros the same size as the relignment parameters
accel=zeros(1,realignment_param);
for vector=1:size(realignment_param,1) % Loop over every vector in the parameter array,
									   % so every set of x,y,z coordinates
    accel(vector)=norm(realignment_param(vector,:)); % Use euclidian norm to convert the vectors
    												 % into euclidian distance or vector magnitude
end
