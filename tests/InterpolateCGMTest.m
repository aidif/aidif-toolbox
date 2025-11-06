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
    properties
        cgmTT
    end

    methods (TestClassSetup)

        function SetupTestTimetable(testCase)
            datetimes = datetime("today") + minutes(0:5:60)';
            cgm = zeros(size(datetimes)) + 100;
            testCase.cgmTT = timetable(cgm,'RowTimes',datetimes);
        end
    end

    methods (Test)

        function firstRowSamplesWithinValidTimes(testCase)
            offHourTT = testCase.cgmTT;
            % sample 1 should always round the the next interval
            offHourTT.Time = offHourTT.Time + minutes(1);
            cgmResampled = AIDIF.interpolateCGM(offHourTT);
            expectedResult = timetable(zeros([12 1]) + 100,'RowTimes',datetime("today") + minutes(5:5:60)',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function lastRowSamplesWithinValidTimes(testCase)
            offHourTT = testCase.cgmTT;
            % end sample should always floor to the previous interval
            offHourTT.Time = offHourTT.Time + minutes(4);
            cgmResampled = AIDIF.interpolateCGM(offHourTT);
            expectedResult = timetable(zeros([12 1]) + 100,'RowTimes',datetime("today") + minutes(5:5:60)',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function interpolationWhenAligned(testCase)
            testTT = testCase.cgmTT;
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(zeros([13 1]) + 100,'RowTimes',datetime("today") + minutes(0:5:60)',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function interpolationWhenUnaligned(testCase)
            testTT = testCase.cgmTT;
            testTT.Time = testTT.Time + minutes(2.5);
            testTT.cgm(1:2:end,:) = 40;
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(zeros([12 1]) + 70,'RowTimes', datetime("today") + minutes(5:5:60)',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function cgmMeasuresAreLimitedAt400(testCase)
            testTT = testCase.cgmTT;
            testTT.cgm = linspace(400.1,600,13)';
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(repmat(400,[13 1]),'RowTimes', datetime("today") + minutes(0:5:60)',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function cgmMeasuresAreLimitedAt40(testCase)
            testTT = testCase.cgmTT;
            testTT.cgm = linspace(39.9,0,13)';
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable(repmat(40,[13 1]),'RowTimes', datetime("today") + minutes(0:5:60)',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function interpolateGapsLessThan30Minutes(testCase)
            testTT = testCase.cgmTT;
            testTT(2:2:end,:) = [];
            testTT.cgm(1:2:end) = 40;
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable([repmat([40 70 100 70],[1 3]) 40]','RowTimes',datetime("today") + minutes(0:5:60)',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function noInterpolationFor30MinuteGaps(testCase)
            testTT = testCase.cgmTT;
            testTT(3:8,:) = [];
            cgmResampled = AIDIF.interpolateCGM(testTT);
            expectedResult = timetable([100 NaN([1 7]) repmat(100,[1 5])]','RowTimes',datetime("today") + minutes(0:5:60)',...
                'VariableNames',"cgm");
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function errorOnMissingCGMVariableName(testCase)
            missedVarName = testCase.cgmTT;
            missedVarName.Properties.VariableNames{'cgm'} = 'glucose';
            verifyError(testCase,@() AIDIF.interpolateCGM(missedVarName),TestHelpers.ERROR_ID_MISSING_COLUMN)
        end

        function errorOnUnsortedData(testCase)
            unsorted = sortrows(testCase.cgmTT,'Time','descend');
            verifyError(testCase,@() AIDIF.interpolateCGM(unsorted),TestHelpers.ERROR_ID_UNSORTED_DATA)
        end
    end
end
