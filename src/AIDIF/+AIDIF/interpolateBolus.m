function ttResampled = interpolateBolus(tt)
%   INTERPOLATEBOLUS Interpolates bolus events to regular spaced (5 minute intervals) insulin deliveries.
%
%   bolusTT = INTERPOLATEBOLUS(tt)
%
%   Inputs:
%     tt - timetable of irregular spaced bolus events:
%        (`bolus` - float column holding the bolus dose (U of insulin) delivered)
%        (`delivery_duration` - duration of delivery (>0 for extended boluses, 0 indicates standard bolus)
%
%   Outputs:
%     bolusTT - timetable with regular spaced (5 minute intervals, aligned to the hour) insulin deliveries:
%        (`InsulinDelivery`: insulin amount (U) delivered each interval (U)

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
    tt timetable {validateBolusTable, validateExtendedDontOverlap}
end

arguments (Output)
    ttResampled timetable
end

ttStandard = tt(tt.delivery_duration==0, "bolus");
ttStandard.Properties.RowTimes = AIDIF.roundTo5Minutes(ttStandard.Properties.RowTimes, "closest");
ttStandard.Properties.VariableNames{'bolus'} = 'InsulinDelivery';

%extended boluses are converted to rates and resampled treating them as basal rates
ttExtended = tt(tt.delivery_duration > 0, :);
if ~isempty(ttExtended)
    ttExtended.rate = ttExtended.bolus ./ hours(ttExtended.delivery_duration);
    zeroRates = timetable(ttExtended.Properties.RowTimes + ttExtended.delivery_duration, ...
                          zeros(height(ttExtended), 1), 'VariableNames', {'rate'});
    
    ttExtendedAsBasalRate = sortrows([ttExtended(:, "rate"); zeroRates]);
    ttExtendedAsBasalRate.Properties.VariableNames{'rate'} = 'basal_rate';

    ttExtendedResampled = AIDIF.interpolateBasal(ttExtendedAsBasalRate);

    ttCombined = [ttStandard; ttExtendedResampled];
else
    ttCombined = ttStandard;
end
newTimes = (AIDIF.roundTo5Minutes(min(ttCombined.Properties.RowTimes), "start"):minutes(5):AIDIF.roundTo5Minutes(max(ttCombined.Properties.RowTimes), 'start'))';
ttResampled = retime(ttCombined,newTimes,"sum");
end

function validateBolusTable(tt)
    if ~all(ismember(["bolus", "delivery_duration"], tt.Properties.VariableNames))
        error(AIDIF.Constants.ERROR_ID_MISSING_COLUMN, "Timetable must have a ''bolus'' and ''delivery_duration'' column.");
    end

    bolus = tt.bolus;
    if ~isnumeric(bolus) || any(~isfinite(bolus)) || any(bolus < 0)
        error(AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE, "''bolus'' column must contain finite, positive values.");
    end
    
    duration = tt.delivery_duration;
    if ~isduration(duration) || any(duration<0)
        error(AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE, "'duration' column must contain positive durations.");
    end
    
    if ~issorted(tt.Properties.RowTimes, "ascend")
        error(AIDIF.Constants.ERROR_ID_UNSORTED_DATA, "Timetable must be sorted ascending by time.");
    end
    
    bDuplicated = AIDIF.findDuplicates(tt(:,[]));
    if sum(bDuplicated)>0
        error(AIDIF.Constants.ERROR_ID_DUPLICATE_TIMESTAMPS, "Timetable has %d rows with duplicated datetimes",num2str(sum(bDuplicated)))
    end
end

function validateExtendedDontOverlap(tt)
    ttExtended = tt(tt.delivery_duration>0,:);
    startEnds = [ttExtended.Properties.RowTimes' ; (ttExtended.Properties.RowTimes + ttExtended.delivery_duration)'];
    interleavedTimes = startEnds(:);
    if sum(diff(interleavedTimes,1)<0)
        error(AIDIF.Constants.ERROR_ID_OVERLAPPING_DELIVERIES, "The timetable contains overlapping extended boluses")
    end
end
