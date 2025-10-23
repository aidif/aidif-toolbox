function [rounded] = roundTimeStamp(dt, location)
%ROUND_TIMESTAMP Round a datetime to the nearest specified interval.
%
%   [ROUNDED] = ROUND_TIMESTAMP(DT, LOCATION) rounds the datetime DT to 
%   the nearest 5-minute interval based on the specified LOCATION.
%
%   Inputs:
%       DT - A datetime object to be rounded.
%       LOCATION - A string specifying whether to round to the "start" 
%                  or "end" of the interval.
%
%   Outputs:
%       ROUNDED - A datetime object rounded to the nearest interval.
%
%   Example:
%       dt = datetime(2023, 10, 1, 12, 3, 0); % 1st October 2023, 12:03:00
%       rounded_start = roundTimeStamp(dt, "start"); % rounds to 12:00
%       rounded_end = roundTimeStamp(dt, "end");     % rounds to 12:05
%
%   Author: Jan Wrede
%   Date: 2025-10-22
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) year, AIDIF
%   All rights reserved
arguments (Input)
    dt {mustBeA(dt, 'datetime')}
    location {mustBeMember(location, ["start", "end"])}
end

arguments (Output)
    rounded {mustBeA(rounded,'datetime')}
end

if location == "start"
    rounded_minute = floor((minute(dt)+second(dt)/60)/5)*5;
else % end
    rounded_minute = ceil((minute(dt)+second(dt)/60)/5)*5;
end
rounded = dateshift(dt, 'start', 'hour') + minutes(rounded_minute);
end