function bolusTT = interpolateBolus(tt)
%   INTERPOLATEBOLUS Interpolates bolus events to regular spaced (5 minute intervals) insulin deliveries.
%
%   bolusTT = INTERPOLATEBOLUS(tt)
%
%   Inputs:
%     tt - timetable of irregular spaced bolus events
%        (`Time` datetime array (5 minute intervals, aligned to midnight)
%        (`bolus` - float column holding the bolus dose (U of insulin) delivered)
%        (`delivery_duration` - duration of delivery (>0 for extended boluses, 0 indicates standard bolus)
%
%   Outputs:
%     bolusTT - timetable with regular spaced (5-minute) insulin deliveries:
%        (`Time`: datetime array (5 minute intervals, aligned to midnight)
%        (`InsulinDelivery`: insulin amount (U) delivered each interval (U)

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
    tt timetable {validateBolusTable, mustBeNonempty}
end

arguments (Output)
    bolusTT timetable
end


%bolusTT = 
end

function validateBolusTable(tt)
    %columns
    if ~all(ismember(["bolus", "delivery_duration"], tt.Properties.VariableNames))
        error('AIDIF:InvalidInput', 'Timetable must have a ''bolus'' and ''delivery_duration'' column.');
    end
    %bolus >0
    bolus = tt.bolus;
    if ~isnumeric(bolus) || any(~isfinite(bolus)) || any(bolus <= 0)
        error('AIDIF:InvalidInput', '''bolus'' column must contain finite, positive values.');
    end
    %duration >= 0
    duration = tt.delivery_duration;
    if ~isduration(duration) || any(duration<0)
        error('AIDIF:InvalidInput', '''duration'' column must contain positive durations.');
    end
    %not empty
    if height(tt) < 1
        error('AIDIF:InvalidInput', 'Timetable must contain at least 1 sample to be resampled.');
    end
    %sorted
    if ~issorted(tt.Properties.RowTimes,"ascend")
        error('AIDIF:InvalidInput', 'Timetable must be sorted ascending by time.');
    end
    % Duplicates
    if any(duplicated(tt.Properties.RowTimes))
        error('AIDIF:InvalidInput', 'Timetable has duplicated timestamps.');
    end
end