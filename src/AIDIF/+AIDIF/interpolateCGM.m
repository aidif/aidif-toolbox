function cgmResampledTimeTable = interpolateCGM(cgmRawTimetable)
% INTERPOLATECGM resample and formats cgm tables on the hour.
%
%   SYNTAX:
%   cgmResampledTimeTable = interpolateCGM(cgmRawTimetable) converts an
%   irregular cgm timetable into resampled timetable that is regular
%   sampled at 5 minutes and synchonized on the hour.
%
%   INPUTS:
%   cgmRawTimetable - timetable containing the following variables:
%       datetime - datetime values of the timetable. The datetime values
%           must not contain duplicates.
%       cgm - egv(mg/dL) for the corresponding datetime values. The cgm 
%           values must numerical.
%
%   OUTPUTS: 
%   cgmResampledTimeTable - resampled timetable with the following variables:
%       datetime - datetime values of the timetable which are regularly
%           spaced by 5 minutes and synced to the hour (00:00, 00:05, 00:10, etc)
%       cgm - egv(mg/dL) which is linearly interpolated to the resampled
%           time series to 1mg/dL precision. if cgmRawTimetable contains gaps 
%           spanning more than 30 minutes, the interpolated values in 
%           cgmResampledTimeTable are set to NaN. 
%
%   EXAMPLES:
%   Add example uses of function syntax, complete with any example data
%       needed.
%
%   See also relevantFunction1, relevantFunction2

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
    cgmRawTimetable timetable %add sorted, add table size add no duplicates
end

arguments (Output)
    cgmResampledTimeTable timetable
end

import AIDIF.roundTimeStamp AIDIF.findGaps

newTimes = roundTimeStamp(cgmRawTimetable.datetime(1),"start"):minutes(5):roundTimeStamp(cgmRawTimetable.datetime(end),"end");
cgmResampledTimeTable = retime(cgmRawTimetable,newTimes,"linear");
gaps = findGaps(cgmRawTimetable,cgmResampledTimeTable,0.5);
cgmResampledTimeTable.cgm(~gaps.valid) = NaN;
cgmResampledTimeTable.cgm = round(cgmResampledTimeTable.cgm);
end
