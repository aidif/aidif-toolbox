function validFlags = findGaps(datetimesIrregular, datetimesRegular, maxGap, includeGapStart)
% FINDGAPS Compute validity flags for resampled datetime array based on data gaps
%
%   validFlags = FINDGAPS(datetimesIrregular, datetimesRegular, maxGapHours) 
%   returns a logical array with the same length as datetimesRegular that
%   indicates whether each resampled datetime falls within a continuous period
%   of data in the original irregular datetime array.
%
%   Inputs:
%       datetimesIrregular - datetime array with original irregularly spaced events
%       datetimesRegular   - datetime array with regularly spaced times
%       maxGap             - duration; maximum time between consecutive events in datetimesIrregular 
%                            before the data is considered missing
%
%   Outputs:
%       validFlags         - logical array with same length as datetimesRegular
%          true if the datetimesRegular datetime occurs within a continuous 
%          data period of datetimesIrregular (gaps < maxGap), and false otherwise. The start of a gap is 
%          marked invalid while the end of a gap is set to valid (unless it is the start of a new gap). 

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
    datetimesIrregular datetime {mustBeSortedDatetime}
    datetimesRegular datetime {mustBeSortedDatetime}
    maxGap {duration}
    includeGapStart {logical} = true
end

arguments (Output)
    validFlags logical
end

timeDiffs = [diff(datetimesIrregular); hours(0)];
valid = timeDiffs <= maxGap;
ttValid = timetable(datetimesIrregular, valid);

% Ensure last sample will be marked invalid
ttValid(ttValid.Properties.RowTimes(end), :) = {false};

if includeGapStart
    %find the true false transition and add move the false one nanosecond, keep a true right before the false
    bGapStarts = ttValid.valid(1:end-1) == true & ~ttValid.valid(2:end);
    gapStartTimes = ttValid.Properties.RowTimes(logical([0;bGapStarts]),:);
    ttValid(gapStartTimes,'valid') = {true};
    ttValid(gapStartTimes+seconds(1e-9),'valid') = {false};
end

ttValid = sortrows(ttValid);

ttValidRegular = retime(ttValid, datetimesRegular, 'previous');
% 
%mask = ismember(datetimesIrregular, ttValidRegular.Properties.RowTimes);
%if any(mask)
%    ttValidRegular(datetimesIrregular(mask), 'valid') = {true};
%end

validFlags = ttValidRegular.valid;
end

% Custom validation function
function mustBeSortedDatetime(dt)
    if ~isdatetime(dt)
        error(AIDIF.Constants.ERROR_ID_INVALID_DATA_TYPE, 'Input must be a datetime array.');
    end
    if any(diff(dt) < 0)
        error(AIDIF.Constants.ERROR_ID_UNSORTED_DATA, 'Datetime array must be sorted in ascending order.');
    end
end
