%   Author: Michael Wheelock
%   Date: 2025-11-03
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved
classdef InterpolateCGMTest < matlab.unittest.TestCase

    methods (Test)

        function firstRowSamplesWithinValidTimes(testCase)
            
            cgmTT = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([1, 10]), ...
                "EGV", [100, 100]);
            
            actual = AIDIF.interpolateCGM(cgmTT);

            expetected = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([5, 10]), ...
                "EGV", [100, 100]);

            verifyEqual(testCase,actual,expetected);
        end

        function lastRowSamplesWithinValidTimes(testCase)

            cgmTT = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([0, 9]), ...
                "EGV", [100, 100]);

            actual = AIDIF.interpolateCGM(cgmTT);

            expetected = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([0, 5]), ...
                "EGV", [100, 100]);

            verifyEqual(testCase,actual,expetected);
        end

        function interpolationWhenAligned(testCase)
            cgmTT = DataHelper.getCGMTT();
            actual = AIDIF.interpolateCGM(cgmTT);
            expected = DataHelper.getCGMTT();
            
            verifyEqual(testCase,actual,expected);
        end

        function interpolationWhenUnaligned(testCase)

            cgmTT = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([2.5, 7.5, 12.5]));

            actual = AIDIF.interpolateCGM(cgmTT);

            expected = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([5, 10]), ...
                "EGV", [100, 100]);

            verifyEqual(testCase,actual,expected);
        end

        function interpolateWhenNoGapsOver30MinutesAligned(testCase)

            cgmTT = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([0, 25]), ...
                "EGV", [40, 140]);

            actual = AIDIF.interpolateCGM(cgmTT);

            expected = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([0, 5, 10, 15, 20, 25]), ...
                "EGV", [40, 60, 80, 100, 120, 140]);

            verifyEqual(testCase,actual,expected);
        end

        function interpolateWhenNoGapsOver30MinutesUnaligned(testCase)

            cgmTT = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([0, 26]), ...
                "EGV", [40, 144]);

            actual = AIDIF.interpolateCGM(cgmTT);

            expected = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes(0:5:25), ...
                "EGV", [40, 60, 80, 100, 120, 140]);

            verifyEqual(testCase,actual,expected);
        end
        
        function interpolateWhenAllGapsOver30MinutesGivesNaN(testCase)
            cgmTT = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([0, 50, 100]));
            actual = AIDIF.interpolateCGM(cgmTT);
            verifyTrue(testCase, all(isnan(actual.cgm)));
        end
        
        function interpolateWhenSomeGapsOver30Minutes(testCase)
            cgmTT = DataHelper.getCGMTT( ...
                "Times", datetime('today') + minutes([0, 5, 36]));

            actual = AIDIF.interpolateCGM(cgmTT);

            expected = DataHelper.getCGMTT(...
                "Times", datetime('today') + minutes(0:5:35), ...
                "EGV", [100, 100, NaN([1 6])]);

            verifyEqual(testCase,actual,expected);
        end

        function errorEVGNonNumeric(testCase)
            cgmTT = DataHelper.getCGMTT("EGV",["90","100","45"]);
            verifyError(testCase,@() AIDIF.interpolateCGM(cgmTT), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE)
        end

        function errorEVGNegative(testCase)
            cgmTT = DataHelper.getCGMTT("EGV",[90,100,-10]);
            verifyError(testCase,@() AIDIF.interpolateCGM(cgmTT), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE)
        end

        function errorWhenInsufficientData(testCase)
            cgmTT = DataHelper.getCGMTT(...
                "Times", datetime('today') + minutes([0]), ...
                "EGV", [100]);
            verifyError(testCase,@() AIDIF.interpolateCGM(cgmTT), AIDIF.Constants.ERROR_ID_INSUFFICIENT_DATA)
        end

        function errorOnMissingCGMVariableName(testCase)
            cgmTT = DataHelper.getCGMTT();
            cgmTT = removevars(cgmTT,"cgm");
            verifyError(testCase,@() AIDIF.interpolateCGM(cgmTT), AIDIF.Constants.ERROR_ID_MISSING_COLUMN)
        end

        function errorOnUnsortedData(testCase)
            cgmTT = DataHelper.getCGMTT("Times", flip(DataHelper.DefaultTimesToday));
            verifyError(testCase,@() AIDIF.interpolateCGM(cgmTT), AIDIF.Constants.ERROR_ID_UNSORTED_DATA)
        end

        function noWarningForEGV400(testCase)
            cgmTT = DataHelper.getCGMTT("EGV", [100,200,400]);
            verifyWarningFree(testCase,@() AIDIF.interpolateCGM(cgmTT), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE)
        end

        function warningForEGVOver400(testCase)
            cgmTT = DataHelper.getCGMTT("EGV", [100,200,401]);
            verifyWarning(testCase,@() AIDIF.interpolateCGM(cgmTT), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE)
        end

        function noWarningForEGV40(testCase)
            cgmTT = DataHelper.getCGMTT("EGV", [40,100,200]);
            verifyWarningFree(testCase,@() AIDIF.interpolateCGM(cgmTT), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE)
        end

        function warningForEGVUnder40(testCase)
            cgmTT = DataHelper.getCGMTT("EGV", [39,100,200]);
            verifyWarning(testCase,@() AIDIF.interpolateCGM(cgmTT), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE)
        end
       
    end
end
