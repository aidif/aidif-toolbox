classdef MergeTotalInsulinTest < matlab.unittest.TestCase
%   Author: Michael Wheelock
%   Date: 2025-11-30
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

    methods (Test)
        
        function correctInsulinAdditions(testCase)
            basalTT  = timetable(datetime('today') + minutes(0:5:20)',[1 1 1 1 1]', ...
                'VariableNames',"basal_rate");
            bolusTT = timetable(datetime("today") + minutes([0 5 10])', [0 1 2]', minutes([0 0 10])', ...
                'VariableNames',["bolus" "delivery_duration"]);
            actualTT = AIDIF.mergeTotalInsulin(basalTT,bolusTT,hours(24));
            expectedTT = timetable(datetime('today')+minutes(0:5:20)',[1 2 1.5 1.5 1.5]', ...
                'VariableNames',"totalInsulin");
        end

        function basalNaNValuesAreConserved(testCase)
            basalTT  = timetable(datetime('today') + minutes([0 20])',[1 1]', ...
                'VariableNames',"basal_rate");
            bolusTT = timetable(datetime("today") + minutes(0:5:20)',[1 1 1 1 1]', minutes([0 0 0 0 0])', ...
                'VariableNames',["bolus" "delivery_duration"]);
            actualTT = AIDIF.mergeTotalInsulin(basalTT,bolusTT,minutes(15));
            expectedTT = timetable(datetime('today') + minutes(0:5:20)',[2 NaN NaN NaN 2]', ...
                'VariableNames',"totalInsulin");
        end

        function bolusNaNValuesAreConserved(testCase)
            basalTT  = timetable(datetime('today') + minutes(0:5:20)',[1 1 1 1 1]', ...
                'VariableNames',"basal_rate");
            bolusTT = timetable(datetime("today") + minutes([0 20])',[1 1]', minutes([0 0])', ...
                'VariableNames',["bolus" "delivery_duration"]);
            actualTT = AIDIF.mergeTotalInsulin(basalTT,bolusTT,minutes(15));
            expectedTT = timetable(datetime('today')+minutes(0:5:20)',[2 NaN NaN NaN 2]', ...
                'VariableNames',"totalInsulin");
        end

        function basalSetsTimeTableLimits(testCase)
            basalTT  = timetable(datetime('today') + minutes([25 30])',[1 1]', ...
                'VariableNames',"basal_rate");
            bolusTT = timetable(datetime("today") + hours([0 0.5 1])', [1 1 1]', minutes([0 0 0])', ...
                'VariableNames',["bolus" "delivery_duration"]);
            actualTT = AIDIF.mergeTotalInsulin(basalTT,bolusTT,hours(24));
            expectedTT = timetable(datetime('today')+minutes([25 30])',[1 2]', ...
                'VariableNames',"totalInsulin");
        end
    end
end
