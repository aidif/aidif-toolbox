%   Author: Jan Wrede
%   Date: 2025-10-22
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

classdef RoundTo5MinutesTest < matlab.unittest.TestCase

    methods(Test)
        function testRoundExactInterval(testCase)
            dt = datetime(2023, 10, 23, 14, 25, 0);

            resultStart = AIDIF.roundTo5Minutes(dt, "start");
            resultEnd = AIDIF.roundTo5Minutes(dt, "end");
            resultClosest = AIDIF.roundTo5Minutes(dt, "closest");
            
            expected = datetime(2023, 10, 23, 14, 25, 0);
            testCase.verifyEqual(resultStart, expected);
            testCase.verifyEqual(resultEnd, expected);
            testCase.verifyEqual(resultClosest, expected);
        end

        function testRoundHourBoundary(testCase)
            dt = datetime(2023, 10, 23, 14, 58, 45);
            
            resultStart = AIDIF.roundTo5Minutes(dt, "start");
            expectedStart = datetime(2023, 10, 23, 14, 55, 0);
            testCase.verifyEqual(resultStart, expectedStart);
            
            resultEnd = AIDIF.roundTo5Minutes(dt, "end");
            expectedEnd = datetime(2023, 10, 23, 15, 0, 0); 
            testCase.verifyEqual(resultEnd, expectedEnd);

            resultClosest = AIDIF.roundTo5Minutes(dt, "closest");
            expectedEnd = datetime(2023, 10, 23, 15, 0, 0);
            testCase.verifyEqual(resultClosest, expectedEnd);
        end

        function testRoundAtZeroMinute(testCase)
            dt = datetime(2023, 10, 23, 14, 0, 30); % 14:00:30
            
            resultStart = AIDIF.roundTo5Minutes(dt, "start");
            expectedStart = datetime(2023, 10, 23, 14, 0, 0); % Round down to 14:00:00
            testCase.verifyEqual(resultStart, expectedStart);
            
            resultEnd = AIDIF.roundTo5Minutes(dt, "end");
            expectedEnd = datetime(2023, 10, 23, 14, 5, 0); % Round up to 14:05:00
            testCase.verifyEqual(resultEnd, expectedEnd);

            resultClosest = AIDIF.roundTo5Minutes(dt, "closest");
            expectedEnd = datetime(2023, 10, 23, 14, 0, 0);
            testCase.verifyEqual(resultClosest, expectedEnd);
        end

        function testArrayOfDatetimes(testCase)
            start = datetime(2023, 10, 23, 14, 20, 0);
            dt = start + minutes(2) + seconds([0,1,29,30,31,59]);
            
            result = AIDIF.roundTo5Minutes(dt, "start");
            expected = start + minutes([0,0,0,0,0,0]);
            testCase.verifyEqual(result, expected);

            result = AIDIF.roundTo5Minutes(dt, "end");
            expected = start + minutes([5,5,5,5,5,5]);
            testCase.verifyEqual(result, expected);

            result = AIDIF.roundTo5Minutes(dt, "closest");
            expected = start + minutes([0,0,0,5,5,5]);
            testCase.verifyEqual(result, expected);
        end

        function testBoundaries(testCase)
            start = datetime(2025, 10, 28, 10, 0, 0);
            dt = start + minutes([0,1,4,5,6,54,55,56,59]);
            
            resultEnd = AIDIF.roundTo5Minutes(dt, "end");
            dtExpectedEnd   = start + minutes([0,5,5,5,10,55,55,60,60]);
            testCase.verifyEqual(resultEnd, dtExpectedEnd);
            
            resultStart = AIDIF.roundTo5Minutes(dt, "start");
            dtExpectedStart = start + minutes([0,0,0,5,5,50,55,55,55]);
            testCase.verifyEqual(resultStart, dtExpectedStart);
            
            resultClosest = AIDIF.roundTo5Minutes(dt, "closest");
            dtExpectedClosest  = start + minutes([0,0,5,5,5,55,55,55,60]);
            testCase.verifyEqual(resultClosest, dtExpectedClosest);
        end
    end
end
