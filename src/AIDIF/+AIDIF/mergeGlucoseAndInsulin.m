function combinedTT = mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT)
% MERGEGLUCOSEANDINSULIN merge resampled glucose, bolus, and basal
% timetables into one timetable
%
%   INPUTS:
%   cgmTT: cgm timetable, resampled to 5 minute intervals and aligned on the hour.
%       (`cgm` - double column of interpolated glucose values (mg/dL))
%   basalTT: basal insulin timetable, resampled to 5 minute intervals and aligned on the hour.
%       (`InsulinDelivery`: insulin delivered each interval (U))
%   bolusTT: bolus timetable, resampled to 5 minute intervals and aligned on the hour.
%        (`InsulinDelivery`: insulin amount (U) delivered each interval (U))
%
%   OUTPUTS: 
%   combinedTT: timetable containing the egv glucose values from cgmTT, alongside the aggregated glucose delivery values
%       from basalTT and bolusTT.
%           (`egv` - estimated glucose value(mg/dL) from cgmTT.
%           (`totalInsulin` - total insulin from the combined insulin deliveries of basalTT and bolusTT for each 
%               time interval. totalInsulin is NaN if either BasalTT or bolusTT is NaN for a given interval.
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
    basalTT timetable {mustBeRegular,mustBeHourAligned}
    bolusTT timetable {mustBeRegular,mustBeHourAligned}
end

arguments (Output)
    combinedTT timetable
end

%synchronize with 0 values to fill trail ends, then repopulate NaN values
mergedInsulin = synchronize(basalTT,bolusTT,'union','fillwithconstant');
mergedInsulin{:,"totalInsulin"} = mergedInsulin{:,1} + mergedInsulin{:,2};
mergedInsulin = removevars(mergedInsulin,[1 2]);
nanRows = [basalTT.Properties.RowTimes(isnan(basalTT.InsulinDelivery));bolusTT.Properties.RowTimes(isnan(bolusTT.InsulinDelivery))];
mergedInsulin{nanRows,"totalInsulin"} = NaN;

combinedTT = synchronize(cgmTT,mergedInsulin,'union','fillwithmissing');
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
