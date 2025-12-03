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

            insulinTT = DataHelper.getTotalInsulinTT();
            cgmTT = DataHelper.getCGMTT();
            expected = DataHelper.getMergedTT();

            actual = AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT);

            verifyEqual(testCase,actual,expected);
        end

        function insulinNaNValuesPreserved(testCase)

            insulinTT = DataHelper.getTotalInsulinTT("Insulin",[1 NaN 1]);
            cgmTT = DataHelper.getCGMTT();
            expected = DataHelper.getMergedTT("Insulin",[1 NaN 1]);

            actual = AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT);
            
            verifyEqual(testCase,actual,expected);
        end

        function cgmNaNValuesPreserved(testCase)

            insulinTT = DataHelper.getTotalInsulinTT();
            cgmTT = DataHelper.getCGMTT("EGV", [100 NaN 100]);
            expected = DataHelper.getMergedTT("EGV",[100 NaN 100]);

            actual = AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT);
            
            verifyEqual(testCase,actual,expected);
        end

        function combinedTableLimitsToIntersection(testCase)

            insulinTT = DataHelper.getTotalInsulinTT( ...
                "Times", datetime("today") + minutes([0 5 10 15 20]),...
                "Insulin",[1 1 1 1 1] ...
                );

            cgmTT = DataHelper.getCGMTT( ...
                "Times", datetime("today") + minutes([10 15 20 25 30]),... 
                "EGV", [100 100 100 100 100]);

            expected = DataHelper.getMergedTT( ...
                "Times", datetime("today") + minutes([10 15 20]));

            actual = AIDIF.mergeGlucoseAndInsulin(cgmTT,insulinTT);

            verifyEqual(testCase,actual,expected);
        end

        function errorOnIrregularInsulin(testCase)
            
            insulinTT = DataHelper.getTotalInsulinTT();
            cgmTT = DataHelper.getCGMTT();

            irregularInsulin = insulinTT([1 1],:);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,irregularInsulin), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)

        end

        function errorOnIrregularEGV(testCase)

            insulinTT = DataHelper.getTotalInsulinTT();
            cgmTT = DataHelper.getCGMTT();

            irregularCGM = cgmTT([1 3],:);
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(irregularCGM,insulinTT), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)
        end

        function errorWhenNotAlignedOnHourEGV(testCase)

            insulinTT = DataHelper.getTotalInsulinTT();

            unalignedCGM = DataHelper.getCGMTT( ...
                "Times", DataHelper.DefaultTimesToday+minutes(2));


            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(unalignedCGM,insulinTT), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)
        end

        function errorWhenNotAlignedOnHourInsulin(testCase)
            
            unalignedInsulin = DataHelper.getTotalInsulinTT( ...
                "Times", DataHelper.DefaultTimesToday+ seconds(2.5));

            cgmTT = DataHelper.getCGMTT();

       
            verifyError(testCase,@() AIDIF.mergeGlucoseAndInsulin(cgmTT,unalignedInsulin), ...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE)

        end
    end
end
