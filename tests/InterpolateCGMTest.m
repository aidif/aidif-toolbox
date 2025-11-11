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
            testTT = timetable(datetime('today') + minutes([1, 10])', [100, 100]','VariableNames',"cgm");
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(datetime("today") + minutes([5, 10])', [100, 100]',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function lastRowSamplesWithinValidTimes(testCase)
            testTT = timetable(datetime('today') + minutes([0, 9])',[100, 100]',...
                'VariableNames',"cgm");
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(datetime("today") + minutes([0, 5])', [100, 100]',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function interpolationWhenAligned(testCase)
            testTT = timetable(datetime('today') + minutes([0, 5, 10])', [50, 100, 50]',...
                'VariableNames',"cgm");
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(datetime("today") + minutes([0, 5, 10])', [50, 100, 50]',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function interpolationWhenUnaligned(testCase)
            testTT = timetable(datetime('today') + minutes([2.5, 7.5, 12.5])', [50, 100, 50]',...
                'VariableNames',"cgm");
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(datetime("today") + minutes([5, 10])', [75,75]',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function interpolateSimple(testCase)
            testTT = timetable(datetime('today') + minutes([0, 25])', [40, 140]', ...
                'VariableNames',"cgm");
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(datetime("today") + minutes(0:5:25)', [40, 60, 80, 100, 120, 140]',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end
        
        function interpolateSimpleUnaligned(testCase)
            testTT = timetable(datetime('today') + minutes([1, 31])', [1, 31]', 'VariableNames',"cgm");
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(datetime("today") + minutes(5:5:30)', (5:5:30)',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled.cgm,expectedResult.cgm,'AbsTol',1e-7);
            verifyEqual(testCase,cgmResampled.Time,expectedResult.Time)
        end
        
        function interpolateOnlyGaps(testCase)
            testTT = timetable(datetime('today') + minutes([0, 50, 100])', [100,100,100]', 'VariableNames',"cgm");
            cgmResampled = AIDIF.interpolateCGM(testTT);
            verifyTrue(testCase, all(isnan(cgmResampled.cgm)));
        end
        
        function noInterpolationFor30MinuteGaps(testCase)
            testTT = timetable(datetime('today') + minutes([0, 5, 40])', [40, 40, 100]', 'VariableNames', "cgm");
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(datetime("today") + minutes(0:5:40)',[40, 40, NaN([1 7])]',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function errorOnMissingCGMVariableName(testCase)
            testTT = timetable(datetime('today') + hours([0, 1, 2])', [100, 100, 100]');
            verifyError(testCase,@() AIDIF.interpolateCGM(testTT), AIDIF.Constants.ERROR_ID_MISSING_COLUMN)
        end

        function errorOnUnsortedData(testCase)
            testTT = timetable(datetime('today') + hours([2, 1, 0])', [100, 100, 100]','VariableNames',"cgm");
            verifyError(testCase,@() AIDIF.interpolateCGM(testTT), AIDIF.Constants.ERROR_ID_UNSORTED_DATA)
        end

        function warningForAnyMeasuresOver400(testCase)
            testTT = timetable(datetime('today') + hours([0, 1, 2])', [350, 400, 450]','VariableNames',"cgm");
            verifyWarning(testCase,@() AIDIF.interpolateCGM(testTT), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE)
        end

        function warningForAnyMeasuresUnder40(testCase)
            testTT = timetable(datetime('today') + hours([0, 1])', [0, 39]','VariableNames',"cgm");
            verifyWarning(testCase,@() AIDIF.interpolateCGM(testTT), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE)
        end
    end
end
