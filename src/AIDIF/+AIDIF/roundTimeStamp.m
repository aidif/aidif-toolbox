function [rounded] = roundTimeStamp(dt, location)
%ROUND_TIMESTAMP Round a datetime to the nearest specified interval.
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