classdef MergeGlucoseAndInsulinTest < matlab.unittest.TestCase
%   Author: Michael Wheelock
%   Date: 2025-11-14
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

    methods (Test)

        function mergeEqualTables(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', [1 1 1]', ...
                'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function insulinNaNValuesPreserved(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 5 10])', [1 NaN 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', [1 NaN 1]', ...
                'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function cgmNaNValuesPreserved(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 NaN 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10])', [100 NaN 100]', [1 1 1]', ...
                'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function combinedTableLimitsToIntersection(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [1 1 1 1 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([10 15 20 25 30])', [100 100 100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([10 15 20])', [100 100 100]', ...
                [1 1 1]', 'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function errorOnIrregularInsulin(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 10])', [1 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)
        end

        function errorOnIrregularEGV(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([0 10])', [100 100]', ...
                'VariableNames',"cgm");

            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)
        end

        function errorWhenNotAlignedOnHourEGV(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([1 6 11])', [100 100 100]', ...
                'VariableNames',"cgm");
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)
        end

        function errorWhenNotAlignedOnHourInsulin(testCase)
            insulinTT = timetable(datetime("today") + minutes([1 6 11])', [1 1 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)
        end
    end
end
