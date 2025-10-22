function ttValid = nanGaps(tt, ttResampled, maxGapHours)
% NANGAPS Compute validity flags for resampled timetable based on data gaps
%
%   ttValid = NANGAPS(tt, ttResampled, maxGapHours) returns a timetable with
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
%                      containing a logical column 'Valid'. 'Valid' is true
%                      if the corresponding resampled row occurs within a
%                      continuous data period (no gap exceeds maxGapHours),
%                      and false otherwise. The start of a gap is marked invalid 
%                      while the end of a gap is set to valid (unless it is the start of a new gap). 

arguments (Input)
    tt timetable {mustBeSortedTimetable}
    ttResampled timetable {mustBeSortedTimetable}
    maxGapHours {mustBePositive} = 6
end

arguments (Output)
    ttValid timetable
end

tt.TimeDiff = [diff(tt.Time);0];
tt.Valid = tt.TimeDiff <= hours(maxGapHours);
ttValid = retime(tt(:,'Valid'), ttResampled.Time, 'previous');
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