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
            basalTT  = timetable(datetime('today') + minutes(0:5:20)',[1.2 1.2 1.2 1.2 1.2]', ...
                'VariableNames',"basal_rate");
            bolusTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 2]', minutes([0 0 10])', ...
                'VariableNames',["bolus" "delivery_duration"]);
            actualTT = AIDIF.mergeTotalInsulin(basalTT,bolusTT,hours(24));
            expectedTT = timetable(datetime('today')+minutes(0:5:15)',[1.1 1.1 NaN NaN]', ...
                'VariableNames',"totalInsulin");
            verifyEqual(testCase,actualTT,expectedTT)
        end

        function basalNaNValuesAreConserved(testCase)
            basalTT  = timetable(datetime('today') + minutes([0 5 25])',[1.2 1.2 1.2]', ...
                'VariableNames',"basal_rate");
            bolusTT = timetable(datetime("today") + minutes(0:5:20)',[1 1 1 1 1]', minutes([0 0 0 0 0])', ...
                'VariableNames',["bolus" "delivery_duration"]);
            actualTT = AIDIF.mergeTotalInsulin(basalTT,bolusTT,minutes(15));
            expectedTT = timetable(datetime('today') + minutes(0:5:20)',[1.1 NaN NaN NaN NaN]', ...
                'VariableNames',"totalInsulin");
            verifyEqual(testCase,actualTT,expectedTT)
        end

        function bolusNaNValuesAreConserved(testCase)
            basalTT  = timetable(datetime('today') + minutes(0:5:25)',[1.2 1.2 1.2 1.2 1.2 1.2]', ...
                'VariableNames',"basal_rate");
            bolusTT = timetable(datetime("today") + minutes([0 20 25])',[1 1 1]', minutes([0 0 0])', ...
                'VariableNames',["bolus" "delivery_duration"]);
            actualTT = AIDIF.mergeTotalInsulin(basalTT,bolusTT,minutes(10));
            expectedTT = timetable(datetime('today')+minutes(0:5:20)',[NaN NaN NaN NaN 1.1]', ...
                'VariableNames',"totalInsulin");
            verifyEqual(testCase,actualTT,expectedTT)
        end

        function returnIntersectionWhenBasalIsBounded(testCase)
            basalTT  = timetable(datetime('today') + minutes([25 30])',[1 1]', ...
                'VariableNames',"basal_rate");
            bolusTT = timetable(datetime("today") + minutes([0 30 60])', [1 1 1]', minutes([0 0 0])', ...
                'VariableNames',["bolus" "delivery_duration"]);
            actualTT = AIDIF.mergeTotalInsulin(basalTT,bolusTT,hours(24));
            expectedTT = timetable(datetime('today')+minutes(25)',5/60', ...
                'VariableNames',"totalInsulin");
            verifyEqual(testCase,actualTT,expectedTT)
        end

        function returnIntersectionWhenBolusIsBounded(testCase)
            basalTT  = timetable(datetime('today') + minutes([0 60])',[1 1]', ...
                'VariableNames',"basal_rate");
            bolusTT = timetable(datetime("today") + minutes([25 30])', [1 1]', minutes([0 0])', ...
                'VariableNames',["bolus" "delivery_duration"]);
            actualTT = AIDIF.mergeTotalInsulin(basalTT,bolusTT,hours(24));
            expectedTT = timetable(datetime('today')+minutes([25 30])',[1+(5/60) NaN]', ...
                'VariableNames',"totalInsulin");
            verifyEqual(testCase,actualTT,expectedTT)
        end
    end
end
