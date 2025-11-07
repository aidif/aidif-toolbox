function cgmTT = interpolateCGM(tt)
% INTERPOLATECGM Interpolates CGM readings to regular spaced (5 minute
% intervals) glucose measurements.
%
%   SYNTAX:
%   cgmTT = interpolateCGM(tt) converts an irregular cgm timetable to a regular timetable that is sampled at 5 minutes 
%       intervals and aligned on the hour.
%
%   INPUTS:
%   tt - timetable of cgm values irregular spaced, sorted and without
%   duplicates.
%       cgm - continuous glucose measurements (mg/dL). Values must be numerical.
%
%   OUTPUTS: 
%   cgmTT - timetable with regular spaced (5 minute intervals, aligned to the hour) cgm measurements:
%       cgm - continuous glucose measurements (mg/dL) linearly interpolated. if tt contains gaps spanning more than 
%           30 minutes, the interpolated values in cgmTT are set to NaN.

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

newTimes = roundTo5Minutes(tt.Properties.RowTimes(1),"end"):minutes(5):roundTo5Minutes(tt.Properties.RowTimes(end),"start");
cgmTT = retime(tt,newTimes,"linear");
isValid = findGaps(tt.Properties.RowTimes,cgmTT.Properties.RowTimes,minutes(30));
cgmTT.cgm(~isValid) = NaN;
end

function validateInputTable(tt)

    if ~ismember('cgm', tt.Properties.VariableNames)
        error(TestHelpers.ERROR_ID_MISSING_COLUMN, "''tt'' must have a ''cgm'' column.");
    end

    cgm = tt.cgm;
    if ~isnumeric(cgm)
        error(TestHelpers.ERROR_ID_INVALID_VALUE_RANGE, "''cgm'' must be numeric.");
    end
    if any(~isfinite(cgm))
        error(TestHelpers.ERROR_ID_INVALID_VALUE_RANGE, "''cgm'' must be finite.");
    end
    if any(cgm < 0)
        error(TestHelpers.ERROR_ID_INVALID_VALUE_RANGE, "''cgm'' must be nonnegative.");
    end

    if any(cgm < 40)
        warning(TestHelpers.ERROR_ID_INVALID_VALUE_RANGE, "'cgm' contains values less than 40 mg/dL.")
    end

    if any(cgm > 400)
        warning(TestHelpers.ERROR_ID_INVALID_VALUE_RANGE, "'cgm' contains values greater than 400 mg/dL.")
    end

    if height(tt) < 2
        error(TestHelpers.ERROR_ID_INSUFFICIENT_DATA, "''tt'' must contain at least two samples to be resampled.");
    end
    
    if ~issorted(tt.Properties.RowTimes,"ascend")
        error(TestHelpers.ERROR_ID_UNSORTED_DATA, "''tt' 'must be sorted ascending by time.");
    end
end
