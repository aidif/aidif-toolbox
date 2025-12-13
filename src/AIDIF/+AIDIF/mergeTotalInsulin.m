function mergedInsulin = mergeTotalInsulin(basalIrregular,bolusIrregular,maxGap)
% MERGETOTALINSULIN combine basal and bolus insulin into total insulin
%   delivery.
%
%   INPUTS:
%     basalIrregular - timetable of irregular spaced basal rate events:
%        (`basal_rate` column holding basal rate in U/hr)
%     bolusIrregular - timetable of irregular spaced bolus events:
%        (`bolus` - float column holding the bolus dose (U of insulin) delivered)
%        (`delivery_duration` - duration of delivery (>0 for extended boluses, 0 indicates standard bolus)
%     maxGap - duration : maximum time between consecutive events in basalIrregular and bolusIrregular timetables 
%        before the data is considered missing
%
%   OUTPUTS: 
%   mergedInsulin: regular timetable of aggregated insulin deliver, sampled
%       at 5 minute intervals on the hour. mergedInsulin is contained
%       within the start and endpoints of basalIrregular. Assigned NaN
%       values within basalIrregular and bolusIrregular are conserved in
%       mergedInsulin.
%           (`totalInsulin` - combined basal and bolus insulin delivery (U) for
%           each 5 minute interval.)
%
%   See also interpolateBasal, interpolateBolus

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

basalRegular = AIDIF.interpolateBasal(basalIrregular);
basalFlag = AIDIF.findGaps(basalIrregular.Properties.RowTimes,basalRegular.Properties.RowTimes,maxGap,false);
basalRegular.InsulinDelivery(~basalFlag) = NaN;

bolusRegular = AIDIF.interpolateBolus(bolusIrregular);
bolusFlag = AIDIF.findGaps(bolusIrregular.Properties.RowTimes,bolusRegular.Properties.RowTimes,maxGap,false);
bolusRegular.InsulinDelivery(~bolusFlag) = NaN;

mergedInsulin = synchronize(basalRegular,bolusRegular,'intersection');
mergedInsulin{:,"totalInsulin"} = mergedInsulin.InsulinDelivery_basalRegular + mergedInsulin.InsulinDelivery_bolusRegular;
mergedInsulin = removevars(mergedInsulin,["InsulinDelivery_basalRegular" "InsulinDelivery_bolusRegular"]);
end
