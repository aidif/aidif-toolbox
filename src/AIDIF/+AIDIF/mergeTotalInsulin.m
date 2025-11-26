function mergedInsulin = mergeTotalInsulin(basalIrregular,bolusIrregular,maxGap)
% MERGETOTALINSULIN combine basal and bolus insuling into total insulin
%   delivery
%
%   INPUTS:
%   basalIrregular: description of inputArg1 argument. If the descsription goes
%       beyond 1 line, indent the following lines
%   bolusIrregular: description of inputArg2 argument.
%   maxGap: description of inputArg2 argument.
%
%   OUTPUTS: 
%   mergedInsulin: description of outputArg1 argument. If the descsription 
%       goes beyond line 1, indent the following lines.
%
%   See also interpolateBasal, interpolateBolus, mergeGlucoseAndInsulin

%   Author: Michael Wheelock
%   Date: 2025-11-26
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

arguments (Input)
    basalIrregular timetable
    bolusIrregular timetable
    maxGap duration 
end

arguments (Output)
    mergedInsulin timetable
end

bolusRegular = AIDIF.interpolateBolus(bolusIrregular);
bolusFlag = AIDIF.findGaps(bolusIrregular.Properties.RowTimes,bolusRegular.Properties.RowTimes,maxGap,false);
bolusRegular.InsulinDelivery(~bolusFlag) = NaN;

basalRegular = AIDIF.interpolateBasal(basalIrregular);
basalFlag = AIDIF.findGaps(basalIrregular.Properties.RowTimes,basalRegular.Properties.RowTimes,maxGap,false);
basalRegular.InsulinDelivery(~basalFlag) = NaN;

mergedInsulin = synchronize(basalRegular,bolusRegular,'first','fillwithmissing');
bolusMatch = ismember(basalRegular.Properties.RowTimes,bolusRegular.Properties.RowTimes);
mergedInsulin{~bolusMatch,2} = 0;
mergedInsulin{:,"totalInsulin"} = mergedInsulin{:,1} + mergedInsulin{:,2};
mergedInsulin = removevars(mergedInsulin,1:2);
end
