function ttValid = findGaps(tt, ttResampled, maxGapHours)
% FINDGAPS Compute validity flags for resampled timetable based on data gaps
%
%   ttValid = FINDGAPS(tt, ttResampled, maxGapHours) returns a timetable with
%   the same row times as ttResampled and a logical column 'Valid' that
%   indicates whether each resampled row falls within a continuous period
%   of data in the original timetable tt.
%
%   Inputs:
%       tt           - timetable with original irregularly spaced events
%       ttResampled  - timetable with regularly spaced row times
%       maxGapHours  - scalar; maximum allowed gap (in hours) between
%                      consecutive events in tt before the data is considered missing
%
%   Outputs:
%       ttValid      - timetable with identical row times as ttResampled
%          ('valid' - logical column. 'valid' is true if the corresponding resampled row occurs within a continuous 
%           data period (no gap exceeds maxGapHours), and false otherwise. The start of a gap is 
%           marked invalid while the end of a gap is set to valid (unless it is the start of a new gap). 

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
    tt timetable {mustBeSortedTimetable}
    ttResampled timetable {mustBeSortedTimetable}
    maxGapHours {mustBePositive} = 6
end

arguments (Output)
    ttValid timetable
end

tt.TimeDiff = [diff(tt.Time);0];
tt.valid = tt.TimeDiff <= hours(maxGapHours);
ttValid = retime(tt(:,'valid'), ttResampled.Time, 'previous');
end

% Custom validation function
function mustBeSortedTimetable(tt)
    if ~istimetable(tt)
        error('Input must be a timetable.');
    end
    if any(diff(tt.Time) < 0)
        error('Timetable must be sorted by time.');
    end
end