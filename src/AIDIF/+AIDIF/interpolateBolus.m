function ttResampled = interpolateBolus(tt)
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
    tt timetable {validateBolusTable, validateExtendedBolusStopTimes}
end

arguments (Output)
    ttResampled timetable
end

ttStandard = tt(tt.delivery_duration==0,'bolus');
ttStandard.Time = AIDIF.roundTo5Minutes(ttStandard.Time,'closest');
ttStandard.Properties.VariableNames{'bolus'} = 'InsulinDelivery';

%extended boluses are converted to rates and resampled treating them as basal rates
ttExtended = tt(tt.delivery_duration > 0, :);
if ~isempty(ttExtended)
    ttExtended.rate = ttExtended.bolus ./ hours(ttExtended.delivery_duration);
    zeroRates = timetable(ttExtended.Properties.RowTimes + ttExtended.delivery_duration, ...
                          zeros(height(ttExtended), 1), 'VariableNames', {'rate'});
    
    ttExtendedAsBasalRate = sortrows([ttExtended(:, 'rate'); zeroRates]);
    ttExtendedAsBasalRate.Properties.VariableNames{'rate'} = 'basal_rate';

    ttExtendedResampled = AIDIF.interpolateBasal(ttExtendedAsBasalRate);

    ttCombined = [ttStandard; ttExtendedResampled];
else
    ttCombined = ttStandard;
end
newTimes = (AIDIF.roundTo5Minutes(min(ttCombined.Time), 'start'):minutes(5):AIDIF.roundTo5Minutes(max(ttCombined.Time), 'start'))';
ttResampled = retime(ttCombined,newTimes,"sum");
end

function validateBolusTable(tt)
    if ~all(ismember(["bolus", "delivery_duration"], tt.Properties.VariableNames))
        error(TestHelpers.ERROR_ID_INVALID_ARGUMENT, "Timetable must have a ''bolus'' and ''delivery_duration'' column.");
    end

    bolus = tt.bolus;
    if ~isnumeric(bolus) || any(~isfinite(bolus)) || any(bolus <= 0)
        error(TestHelpers.ERROR_ID_INVALID_ARGUMENT, "''bolus'' column must contain finite, positive values.");
    end
    
    duration = tt.delivery_duration;
    if ~isduration(duration) || any(duration<0)
        error(TestHelpers.ERROR_ID_INVALID_ARGUMENT, "'duration' column must contain positive durations.");
    end
    
    if ~issorted(tt.Properties.RowTimes,"ascend")
        error(TestHelpers.ERROR_ID_INVALID_ARGUMENT, "Timetable must be sorted ascending by time.");
    end
    
    bDuplicated = AIDIF.findDuplicates(tt(:,[]));
    if sum(bDuplicated)>0
        error(TestHelpers.ERROR_ID_INVALID_ARGUMENT, "Timetable has %d rows with duplicated datetimes",num2str(sum(bDuplicated)))
    end
end

function validateExtendedBolusStopTimes(tt)
    startEnds = [tt.Properties.RowTimes' ; (tt.Properties.RowTimes + tt.delivery_duration)'];
    interleavedTimes = startEnds(:);
    if sum(diff(interleavedTimes,1)<0)
        error(TestHelpers.ERROR_ID_INVALID_ARGUMENT, "The timetable contains boluses whose deliveries overlap")
    end
end
