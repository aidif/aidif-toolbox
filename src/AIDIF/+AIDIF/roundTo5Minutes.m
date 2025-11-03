function [rounded] = roundTo5Minutes(dt, location)
% ROUNDTO5MINUTES Round a datetime to the nearest 5-minute interval synced to the hour.
%
%   [ROUNDED] = ROUNDTO5MINUTES(DT, LOCATION) rounds the datetime DT to 
%   the nearest 5-minute interval based on the specified LOCATION.
%   An interval is a 5-minute timestamp synced on the hour (e.g., :00, :05, :10, etc.).
%
%   Inputs:
%       dt - A datetime object to be rounded.
%       location - A string ["start", "end", "closest"] specifying whether to round to the 
%                  "start", "end" of the 5-minute interval or whichever is "closest".
%
%   Outputs:
%       rounded - A datetime object rounded to the nearest 5-minute interval.
%
%   Example:
%       dt = datetime(2023, 10, 1, 12, 3, 0);
%       roundTo5Minutes(dt, "start");   % rounds to 12:00
%       roundTo5Minutes(dt, "end");     % rounds to 12:05
%       roundTo5Minutes(dt, "closest"); % rounds to 12:05

%   Author: Jan Wrede
%   Date: 2025-10-22
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved
arguments (Input)
    dt {mustBeA(dt, 'datetime')}
    location {mustBeMember(location, ["start", "end", "closest"])}
end

arguments (Output)
    rounded {mustBeA(rounded,'datetime')}
end

if location == "start"
    roundedMinute = floor((minute(dt)+second(dt)/60)/5)*5;
elseif location == "end"
    roundedMinute = ceil((minute(dt)+second(dt)/60)/5)*5;
elseif location == "closest"
    roundedMinute = round((minute(dt)+second(dt)/60)/5)*5;
end
rounded = dateshift(dt, "start", "hour") + minutes(roundedMinute);
end
