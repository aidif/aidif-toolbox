function basalTT = interpolateBasal(tt)
%   INTERPOLATEBASAL Interpolates basal rates to equally spaced 5 minute insulin deliveries.
%
%   basalTT = INTERPOLATEBASAL(tt)
%
%   Inputs:
%     tt         - timetable containing a column 'BasalRate' with basal rate (U/hr)
%
%   Outputs:
%     basalTT - timetable with 5-minute intervals containing:
%               Time: datetime array (5 minute intervals, aligned to midnight)
%               InsulinDelivery: amount delivered in 5 minute interval (U)
arguments (Input)
    tt timetable {validateBasalTable, mustBeNonempty}
end

arguments (Output)
    basalTT timetable
end

% Ensure column vectors
timestamps = tt.Properties.RowTimes;
basal_rate = tt.basal_rate;

% Calculate cumulative insulin delivery
time_diff = diff(timestamps);
time_diff_hours = hours(time_diff);
cum_delivery = [0; cumsum(time_diff_hours .* basal_rate(1:end-1), "omitmissing")];

% Calculate 5 minute deliveries from midnight to midnight, continue last basal rate until end
dti = (AIDIF.roundTimeStamp(min(timestamps),'start'):minutes(5):AIDIF.roundTimeStamp(max(timestamps),'end'))';
cum_deliveryi = interp1(timestamps, cum_delivery, dti, "linear");
cum_deliveryi = fillmissing(cum_deliveryi ,"previous");
deliveryi = diff(cum_deliveryi);
deliveryi = [deliveryi; 0];


% Create output timetable
basalTT = timetable(dti, deliveryi, 'VariableNames', {'InsulinDelivery'});

end


function validateBasalTable(tt)
    if ~ismember('basal_rate', tt.Properties.VariableNames)
        error('Input timetable must have a ''basal_rate'' column.');
    end
    br = tt.basal_rate;
    if ~isnumeric(br) || any(~isfinite(br)) || any(br < 0)
        error('''basal_rate'' must contain finite, nonnegative numeric values.');
    end
    
    if height(tt) < 2
        error('Basal Rate timetable must contain at least two samples to be resampled.');
    end
end