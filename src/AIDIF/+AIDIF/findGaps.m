function validFlags = findGaps(datetimesIrregular, datetimesRegular, maxGapHours)
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
%       maxGapHours        - scalar; maximum allowed gap (in hours) between
%                           consecutive events in datetimesIrregular before the data is considered missing
%
%   Outputs:
%       validFlags         - logical array with same length as datetimesRegular
%          validFlags is true if the corresponding resampled datetime occurs within a continuous 
%          data period (no gap exceeds maxGapHours), and false otherwise. The start of a gap is 
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
    maxGapHours {mustBePositive}
end

arguments (Output)
    validFlags logical
end

timeDiffs = [diff(datetimesIrregular); hours(0)];
valid = timeDiffs <= hours(maxGapHours);

ttValid = timetable(datetimesIrregular, valid);%;, 'VariableNames', {'valid'});
ttValidRegular = retime(ttValid, datetimesRegular, 'previous');

validFlags = ttValidRegular.valid;
end

% Custom validation function
function mustBeSortedDatetime(dt)
    if ~isdatetime(dt)
        error('Input must be a datetime array.');
    end
    if any(diff(dt) < 0)
        error('Datetime array must be sorted in ascending order.');
    end
end
