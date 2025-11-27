function combinedTT = mergeGlucoseAndInsulin(cgmTT,totalInsulinTT)
% MERGEGLUCOSEANDINSULIN merge resampled glucose, bolus, and basal
% timetables into one timetable
%
%   INPUTS:
%   cgmTT: cgm timetable, resampled to 5 minute intervals and aligned on the hour.
%       (`cgm` - double column of interpolated glucose values (mg/dL))
%   totalInsulinTT: timetable of the total insulin delivery, resampled to 5 minute intervals and aligned on the hour.
%       (`totalInsulin`: insulin delivered each interval (U))
%
%   OUTPUTS: 
%   combinedTT: timetable containing the egv glucose values from cgmTT, alongside the aggregated glucose delivery values
%       from basalTT and bolusTT.
%           (`egv` - estimated glucose value(mg/dL) from cgmTT.
%           (`totalInsulin` - total insulin from the combined insulin deliveries of basalTT and bolusTT for each 
%               time interval.
%
%   See also interpolateBasal, interpolateBolus, interpolateCGM

%   Author: Michael Wheelock
%   Date: 2025-11-13
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

arguments (Input)
    cgmTT timetable {mustBeRegular,mustBeHourAligned}
    totalInsulinTT timetable {mustBeRegular,mustBeHourAligned}
end

arguments (Output)
    combinedTT timetable
end

% Add egv data. clip data to the common range of data
combinedTT = synchronize(cgmTT,totalInsulinTT,'intersection','fillwithmissing');
combinedTT = renamevars(combinedTT,"cgm","egv");

end

function mustBeRegular(tt)
if any(diff(tt.Properties.RowTimes)~= minutes(5))
    error(TestHelpers.ERROR_ID_INCONSISTENT_STRUCTURE,"timetable is not regular at 5 minute intervals.")
end
end

function mustBeHourAligned(tt)
time = tt.Properties.RowTimes;
if ~all(ismember(minute(time),0:5:55)) || any(second(time))
    error(TestHelpers.ERROR_ID_INCONSISTENT_STRUCTURE,"timetable is not aligned to the hour.")
end
end
