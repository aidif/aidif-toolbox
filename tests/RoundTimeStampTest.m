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
            expected = datetime(2023, 10, 23, 14, 25, 0);
            
            testCase.verifyEqual(resultStart, expected);
            testCase.verifyEqual(resultEnd, expected);
        end

        function testRoundHourBoundary(testCase)
            % Test rounding near hour boundary
            dt = datetime(2023, 10, 23, 14, 58, 45); % 14:58:45
            
            resultStart = AIDIF.roundTimeStamp(dt, "start");
            expectedStart = datetime(2023, 10, 23, 14, 55, 0); % Round down to 14:55:00
            testCase.verifyEqual(resultStart, expectedStart);
            
            resultEnd = AIDIF.roundTimeStamp(dt, "end");
            expectedEnd = datetime(2023, 10, 23, 15, 0, 0); % Round up to 15:00:00
            testCase.verifyEqual(resultEnd, expectedEnd);
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
        end

        function testArrayOfDatetimes(testCase)
            % Test with array of datetimes
            dt = [datetime(2023, 10, 23, 14, 22, 0);
                  datetime(2023, 10, 23, 14, 22, 1);  
                  datetime(2023, 10, 23, 14, 22, 29); 
                  datetime(2023, 10, 23, 14, 22, 30); 
                  datetime(2023, 10, 23, 14, 22, 31); 
                  datetime(2023, 10, 23, 14, 22, 59)];
            
            resultStart = AIDIF.roundTimeStamp(dt, "start");
            expectedStart = [datetime(2023, 10, 23, 14, 20,0);   
                             datetime(2023, 10, 23, 14, 20,0);
                             datetime(2023, 10, 23, 14, 20,0);
                             datetime(2023, 10, 23, 14, 20,0);
                             datetime(2023, 10, 23, 14, 20,0);
                             datetime(2023, 10, 23, 14, 20,0)];
            testCase.verifyEqual(resultStart, expectedStart);
            
            resultEnd = AIDIF.roundTimeStamp(dt, "end");
            expectedEnd = [datetime(2023, 10, 23, 14, 25,0);   
                           datetime(2023, 10, 23, 14, 25,0);
                           datetime(2023, 10, 23, 14, 25,0);
                           datetime(2023, 10, 23, 14, 25,0);
                           datetime(2023, 10, 23, 14, 25,0);
                           datetime(2023, 10, 23, 14, 25,0)];
            
            testCase.verifyEqual(resultEnd, expectedEnd);
        end

    end
end