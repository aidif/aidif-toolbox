function basalTT = interpolateBasal(tt)
%   INTERPOLATEBASAL Interpolates basal rates to regular spaced (5 minute intervals) insulin deliveries.
%
%   basalTT = INTERPOLATEBASAL(tt)
%
%   Inputs:
%     tt      - timetable of irregular spaced basal rate events
%     (`basal_rate` column holding basal rate in U/hr)
%
%   Outputs:
%     basalTT - timetable with regular spaced (5-minute) insulin deliveries:
%               Time: datetime array (5 minute intervals, aligned to midnight)
%               InsulinDelivery: insulin amount (U) delivered each interval (U)
%
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
    tt timetable {validateBasalTable, mustBeNonempty}
end

arguments (Output)
    basalTT timetable
end

timestamps = tt.Properties.RowTimes;
basal_rate = tt.basal_rate;

% Calculate 5 minute deliveries from midnight to midnight, continue last basal rate until end
dti = (AIDIF.roundTimeStamp(min(timestamps),'start'):minutes(5):AIDIF.roundTimeStamp(max(timestamps),'end'))';

% If the last basal rate is not aligned with the final sample (e.g., 00:32 vs 00:35),
% repeat it at the final sample to avoid extrapolating the previous rate
% and ensure correct calculation of the last partial delivery in the next steps.
if max(dti) ~= timestamps(end)
    timestamps = [timestamps;max(dti)];
    basal_rate = [basal_rate;basal_rate(end)];
end

%Calculate cumulative insulin delivery
cum_delivery = [0; cumsum(hours(diff(timestamps)) .* basal_rate(1:end-1), "omitmissing")];
cum_deliveryi = interp1(timestamps, cum_delivery, dti, "linear",'extrap');
% this ensures the first partial delivery is extrapolated correctly
cum_deliveryi(1) = 0;
deliveryi = diff(cum_deliveryi);

basalTT = timetable(dti(1:end-1), deliveryi, 'VariableNames', {'InsulinDelivery'});
end

function validateBasalTable(tt)
    if ~ismember('basal_rate', tt.Properties.VariableNames)
        error('AIDIF:InvalidInput', 'Input timetable must have a ''basal_rate'' column.');
    end
    br = tt.basal_rate;
    if ~isnumeric(br) || any(~isfinite(br)) || any(br < 0)
        error('AIDIF:InvalidInput', '''basal_rate'' must contain finite, nonnegative numeric values.');
    end
    
    if height(tt) < 2
        error('AIDIF:InvalidInput', 'Basal Rate timetable must contain at least two samples to be resampled.');
    end
    if ~issorted(tt.Properties.RowTimes,"ascend")
        error('AIDIF:InvalidInput', 'Input timetable must be sorted ascending by time.');
    end
end