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
            basalTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"InsulinDelivery");
            bolusTT = timetable(datetime("today") + minutes([0 5 10])', [0 1 1]', ...
                'VariableNames',"InsulinDelivery");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', [1 2 2]', ...
                'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function basalNanValuesPreserved(testCase)
            basalTT = timetable(datetime("today") + minutes([0 5 10])', [1 NaN 1]', ...
                'VariableNames',"InsulinDelivery");
            bolusTT = timetable(datetime("today") + minutes([0 5 10])', [0 1 1]', ...
                'VariableNames',"InsulinDelivery");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', [1 NaN 2]', ...
                'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function bolusNanValuesPreserved(testCase)
            basalTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"InsulinDelivery");
            bolusTT = timetable(datetime("today") + minutes([0 5 10])', [0 NaN 1]', ...
                'VariableNames',"InsulinDelivery");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', [1 NaN 2]', ...
                'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function cgmNanValuesPreserved(testCase)
            basalTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"InsulinDelivery");
            bolusTT = timetable(datetime("today") + minutes([0 5 10])', [0 1 1]', ...
                'VariableNames',"InsulinDelivery");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 NaN 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10])', [100 NaN 100]', [1 2 2]', ...
                'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function basalBeyondRangeIsZero(testCase)
            basalTT = timetable(datetime("today") + minutes([5 10 15])', [1 1 1]', ...
                'VariableNames',"InsulinDelivery");
            bolusTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [0 1 1 0 1 ]', ...
                'VariableNames',"InsulinDelivery");
            cgmTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [100 100 100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [100 100 100 100 100]', ...
                [0 2 2 1 1]', 'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function bolusBeyondRangeIsZero(testCase)
            basalTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [1 1 1 1 1 ]', ...
                'VariableNames',"InsulinDelivery");
            bolusTT = timetable(datetime("today") + minutes([5 10 15])', [1 0 1]', ...
                'VariableNames',"InsulinDelivery");
            cgmTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [100 100 100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [100 100 100 100 100]', ...
                [1 2 1 2 1]', 'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function cgmBeyoneRangeIsNan(testCase)
            basalTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [1 1 1 1 1 ]', ...
                'VariableNames',"InsulinDelivery");
            bolusTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [1 0 1 0 1]', ...
                'VariableNames',"InsulinDelivery");
            cgmTT = timetable(datetime("today") + minutes([5 10 15])', [100 100 100]', ...
                'VariableNames',"cgm");

            expectedTT = timetable(datetime("today") + minutes([0 5 10 15 20])', [NaN 100 100 100 NaN]', ...
                [2 1 2 1 2]', 'VariableNames',["egv", "totalInsulin"]);
            actualTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT);
            verifyEqual(testCase,actualTT,expectedTT);
        end

        function errorOnIrregularTimes(testCase)
            basalTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"InsulinDelivery");
            bolusTT = timetable(datetime("today") + minutes([0 5 10])', [0 1 1]', ...
                'VariableNames',"InsulinDelivery");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            % check basal
            irregularBasal = basalTT([1 3],:);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,irregularBasal,bolusTT), ...
                TestHelpers.ERROR_ID_INCONSISTENT_STRUCTURE)

            % check bolus
            irregularBolus = bolusTT([1 3],:);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,irregularBolus), ...
                TestHelpers.ERROR_ID_INCONSISTENT_STRUCTURE)

            % check cgm
            irregularCGM = cgmTT([1 3],:);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(irregularCGM,basalTT,bolusTT), ...
                TestHelpers.ERROR_ID_INCONSISTENT_STRUCTURE)
        end

        function errorWhenNotAlignedOnHour(testCase)
            basalTT = timetable(datetime("today") + minutes([0 5 10])', [1 1 1]', ...
                'VariableNames',"InsulinDelivery");
            bolusTT = timetable(datetime("today") + minutes([0 5 10])', [0 1 1]', ...
                'VariableNames',"InsulinDelivery");
            cgmTT = timetable(datetime("today") + minutes([0 5 10])', [100 100 100]', ...
                'VariableNames',"cgm");

            % check basal
            unalignedBasal = basalTT;
            unalignedBasal.Properties.RowTimes = unalignedBasal.Properties.RowTimes + seconds(2.5);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,unalignedBasal,bolusTT), ...
                TestHelpers.ERROR_ID_INCONSISTENT_STRUCTURE)

            % check bolus
            unalignedBolus = bolusTT;
            unalignedBolus.Properties.RowTimes = unalignedBolus.Properties.RowTimes + minutes(2);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,unalignedBolus), ...
                TestHelpers.ERROR_ID_INCONSISTENT_STRUCTURE)

            % check cgm
            unalignedCGM = cgmTT;
            unalignedCGM.Properties.RowTimes = unalignedCGM.Properties.RowTimes + minutes(2);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(unalignedCGM,basalTT,bolusTT), ...
                TestHelpers.ERROR_ID_INCONSISTENT_STRUCTURE)
        end
    end

end
