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

        function insulinNanValuesPreserved(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 5 10])', [1 NaN 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', [1 NaN 1]', ...
                'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function cgmNanValuesPreserved(testCase)
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

        function errorOnIrregularTimes(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            % check insulin
            irregularInsulin = insulinTT([1 3],:);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,irregularInsulin), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)

            % check cgm
            irregularCGM = cgmTT([1 3],:);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(irregularCGM,insulinTT), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)
        end

        function errorWhenNotAlignedOnHour(testCase)
            insulinTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"totalInsulin");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            % check insulin
            unalignedInsulin = insulinTT;
            unalignedInsulin.Properties.RowTimes = unalignedInsulin.Properties.RowTimes + seconds(2.5);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,unalignedInsulin), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)

            % check cgm
            unalignedCGM = cgmTT;
            unalignedCGM.Properties.RowTimes = unalignedCGM.Properties.RowTimes + minutes(2);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(unalignedCGM,insulinTT), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)
        end
    end

end
