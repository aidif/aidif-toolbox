function cgmTT = interpolateCGM(tt)
% INTERPOLATECGM resample and formats cgm tables on the hour.
%
%   SYNTAX:
%   cgmTT = interpolateCGM(tt) converts an irregular cgm timetable to a regular timetable that is sampled at 5 minutes 
%       intervals and synchonized on the hour.
%
%   INPUTS:
%   tt - timetable containing the following variables:
%       Time - datetime values of the timetable. The datetime values
%           must not contain duplicates.
%       cgm - cgm glucose values(mg/dL) for the corresponding datetime values. The cgm 
%           values must be numerical.
%
%   OUTPUTS: 
%   cgmTT - resampled timetable with the following variables:
%       Time - datetime values of the timetable which are regularly
%           spaced by 5 minutes and aligned to the hour.
%       cgm - cgm glucose values(mg/dL) which are linearly interpolated to the resampled
%           time series. if tt contains gaps spanning more than 30 minutes, the interpolated values in 
%           cgmTT are set to NaN. 

%   Author: Michael Wheelock
%   Date: 2025-11-03
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
    cgmTT timetable
end

import AIDIF.roundTo5Minutes AIDIF.findGaps

newTimes = roundTo5Minutes(tt.Time(1),"end"):minutes(5):roundTo5Minutes(tt.Time(end),"start");
cgmTT = retime(tt,newTimes,"linear");
isValid = findGaps(tt.Time,cgmTT.Time,minutes(30));
cgmTT.cgm(~isValid) = NaN;
end

function validateInputTable(tt)

    if ~ismember('cgm', tt.Properties.VariableNames)
        error(TestHelpers.ERROR_ID_MISSING_COLUMN, "''tt'' must have a ''cgm'' column.");
    end

    cgm = tt.cgm;
    if ~isnumeric(cgm) || any(~isfinite(cgm)) || any(cgm < 0)
        error(TestHelpers.ERROR_ID_INVALID_VALUE_RANGE, "''cgm'' must contain finite, nonnegative numeric values.");
    end
    
    if height(tt) < 2
        error(TestHelpers.ERROR_ID_INSUFFICIENT_DATA, "''tt'' must contain at least two samples to be resampled.");
    end
    
    if ~issorted(tt.Properties.RowTimes,"ascend")
        error(TestHelpers.ERROR_ID_UNSORTED_DATA, "''tt''must be sorted ascending by time.");
    end
end
