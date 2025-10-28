%   Author: Jan Wrede
%   Date: 2025-10-22
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

classdef RoundTimeStampTest < matlab.unittest.TestCase

    methods(Test)
        function testRoundExactInterval(testCase)
            % Test rounding when already at exact 5-minute interval
            dt = datetime(2023, 10, 23, 14, 25, 0); % 14:25:00
            
            % Both start and end should return the same value when exactly at interval
            resultStart = AIDIF.roundTimeStamp(dt, "start");
            resultEnd = AIDIF.roundTimeStamp(dt, "end");
            resultClosest = AIDIF.roundTimeStamp(dt, "closest");
            expected = datetime(2023, 10, 23, 14, 25, 0);
            
            testCase.verifyEqual(resultStart, expected);
            testCase.verifyEqual(resultEnd, expected);
            testCase.verifyEqual(resultClosest, expected);
        end

        function testRoundHourBoundary(testCase)
            % Test rounding near hour boundary
            dt = datetime(2023, 10, 23, 14, 58, 45);
            
            resultStart = AIDIF.roundTimeStamp(dt, "start");
            expectedStart = datetime(2023, 10, 23, 14, 55, 0);
            testCase.verifyEqual(resultStart, expectedStart);
            
            resultEnd = AIDIF.roundTimeStamp(dt, "end");
            expectedEnd = datetime(2023, 10, 23, 15, 0, 0); 
            testCase.verifyEqual(resultEnd, expectedEnd);

            resultClosest = AIDIF.roundTimeStamp(dt, "closest");
            expectedEnd = datetime(2023, 10, 23, 15, 0, 0);
            testCase.verifyEqual(resultClosest, expectedEnd);
        end

        function testRoundAtZeroMinute(testCase)
            % Test rounding at zero minute
            dt = datetime(2023, 10, 23, 14, 0, 30); % 14:00:30
            
            resultStart = AIDIF.roundTimeStamp(dt, "start");
            expectedStart = datetime(2023, 10, 23, 14, 0, 0); % Round down to 14:00:00
            testCase.verifyEqual(resultStart, expectedStart);
            
            resultEnd = AIDIF.roundTimeStamp(dt, "end");
            expectedEnd = datetime(2023, 10, 23, 14, 5, 0); % Round up to 14:05:00
            testCase.verifyEqual(resultEnd, expectedEnd);

            resultClosest = AIDIF.roundTimeStamp(dt, "closest");
            expectedEnd = datetime(2023, 10, 23, 14, 0, 0);
            testCase.verifyEqual(resultClosest, expectedEnd);
        end

        function testArrayOfDatetimes(testCase)
            start = datetime(2023, 10, 23, 14, 20, 0);
            dt = start + minutes(2) + seconds([0,1,29,30,31,59]);
            
            
            result = AIDIF.roundTimeStamp(dt, "start");
            expected = start + minutes([0,0,0,0,0,0]);
            testCase.verifyEqual(result, expected);

            result = AIDIF.roundTimeStamp(dt, "end");
            expected = start + minutes([5,5,5,5,5,5]);
            testCase.verifyEqual(result, expected);

            result = AIDIF.roundTimeStamp(dt, "closest");
            expected = start + minutes([0,0,0,5,5,5]);
            testCase.verifyEqual(result, expected);

        end


        function testBoundaries(testCase)
            % Test with array of datetimes
            start = datetime(2025, 10, 28, 10, 0, 0);
            dt = start + minutes([0,1,4,5,6,54,55,56,59]);
            
            
            resultEnd = AIDIF.roundTimeStamp(dt, "end");
            dtExpectedEnd   = start + minutes([0,5,5,5,10,55,55,60,60]);
            testCase.verifyEqual(resultEnd, dtExpectedEnd);
            
            resultStart = AIDIF.roundTimeStamp(dt, "start");
            dtExpectedStart = start + minutes([0,0,0,5,5,50,55,55,55]);
            testCase.verifyEqual(resultStart, dtExpectedStart);
            
            resultClosest = AIDIF.roundTimeStamp(dt, "closest");
            dtExpectedClosest  = start + minutes([0,0,5,5,5,55,55,55,60]);
            testCase.verifyEqual(resultClosest, dtExpectedClosest);
        end


    end
end