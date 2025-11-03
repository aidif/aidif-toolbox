function basalTT = interpolateBasal(tt)
%   INTERPOLATEBASAL Interpolates basal rates to regular spaced (5 minute intervals) insulin deliveries.
%
%   basalTT = INTERPOLATEBASAL(tt)
%
%   Inputs:
%     tt - timetable of irregular spaced basal rate events
%        (`basal_rate` column holding basal rate in U/hr)
%
%   Outputs:
%     basalTT - timetable with regular spaced (5-minute) insulin deliveries:
%        (`Time`: datetime array (5 minute intervals, aligned to midnight)
%        (`InsulinDelivery`: insulin delivered each interval (Units of Insulin))

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
    tt timetable {validateInputTable, mustBeNonempty}
end

arguments (Output)
    basalTT timetable
end

datetimes = tt.Properties.RowTimes;
basalRate = tt.basal_rate;

% Generate 5 minute regular spaced and datetimes aligned to the hour.
datetimesResampled = (AIDIF.roundTo5Minutes(min(datetimes),"start"):minutes(5):AIDIF.roundTo5Minutes(max(datetimes),"end"))';

% If the last basal rate is not aligned with the final sample (e.g., 00:32 vs 00:35),
% repeat it at the final sample to avoid extrapolating the previous rate
% and ensure correct calculation of the last partial delivery in the next steps.
if max(datetimesResampled) ~= datetimes(end)
    datetimes = [datetimes;max(datetimesResampled)];
    basalRate = [basalRate;basalRate(end)];
end

% Calculate cumulative insulin delivery.
cumulativeDelivery = [0; cumsum(hours(diff(datetimes)) .* basalRate(1:end-1), "omitmissing")];
cumulativeDeliveryResampled = interp1(datetimes, cumulativeDelivery, datetimesResampled, "linear", "extrap");
% Ensure that the first partial delivery is extrapolated correctly.
cumulativeDeliveryResampled(1) = 0;

basalTT = timetable(datetimesResampled(1:end-1), diff(cumulativeDeliveryResampled), ...
    'VariableNames', {'InsulinDelivery'});
end

function validateInputTable(tt)
    if ~ismember('basal_rate', tt.Properties.VariableNames)
        error(TestHelpers.ERROR_ID_MISSING_COLUMN, "''tt'' must have a ''basal_rate'' column.");
    end
    br = tt.basal_rate;
    if ~isnumeric(br) || any(~isfinite(br)) || any(br < 0)
        error(TestHelpers.ERROR_ID_INVALID_VALUE_RANGE, "''basal_rate'' must contain finite, nonnegative numeric values.");
    end
    
    if height(tt) < 2
        error(TestHelpers.ERROR_ID_INSUFFICIENT_DATA, "''tt'' must contain at least two samples to be resampled.");
    end
    if ~issorted(tt.Properties.RowTimes,"ascend")
        error(TestHelpers.ERROR_ID_UNSORTED_DATA, "''tt''must be sorted ascending by time.");
    end
end
