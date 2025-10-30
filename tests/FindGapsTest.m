%   Author: Jan Wrede
%   Date: 2025-10-22
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

classdef FindGapsTest < matlab.unittest.TestCase
    methods(Test)
        function testNoGaps(testCase)
            datetimesIrregular = datetime("today") + hours(0:1:3);
            datetimesRegular = datetimesIrregular(1):minutes(5):datetimesIrregular(end);
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', 6);
            testCase.verifyTrue(all(validFlags));
            testCase.verifyEqual(length(validFlags), length(datetimesRegular));
        end

        function testAllGaps(testCase)
            datetimesIrregular = datetime("today") + hours([0, 2, 4]);
            datetimesRegular = datetimesIrregular(1):minutes(15):datetimesIrregular(end);
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', 1);
            testCase.verifyTrue(all(validFlags(1:end-1)==false));
            testCase.verifyTrue(validFlags(end));
        end

        function testSingleGap(testCase)
            datetimesIrregular = datetime("today") + hours([0, 1, 8, 9]); 
            datetimesRegular = datetimesIrregular(1):minutes(5):datetimesIrregular(end);
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', 6);
            gapStart = find(datetimesRegular == datetimesIrregular(2)); 
            gapEnd   = find(datetimesRegular < datetimesIrregular(3), 1, 'last');
            testCase.verifyTrue(all(validFlags(1:gapStart-1))); 
            testCase.verifyFalse(any(validFlags(gapStart:gapEnd)));
        end

        function testMultipleGaps(testCase)
            datetimesIrregular = datetime("today") + hours([0,1,4,5,8]);
            datetimesRegular = datetimesIrregular(1):minutes(30):datetimesIrregular(end);
            
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', 2);
            
            % Check that periods between 1-4 and 5-8 hours are invalid
            gap1Start = find(datetimesRegular > datetimesIrregular(2), 1)-1;
            gap1End   = find(datetimesRegular < datetimesIrregular(3), 1, 'last');
            testCase.verifyFalse(any(validFlags(gap1Start:gap1End)));
            
            gap2Start = find(datetimesRegular > datetimesIrregular(4), 1)-1;
            gap2End   = find(datetimesRegular < datetimesIrregular(5), 1, 'last');
            testCase.verifyFalse(any(validFlags(gap2Start:gap2End)));
        end

        function testOutputLengthMatch(testCase)
            datetimesIrregular = datetime("today") + hours([0,1,2,3]);
            datetimesRegular = datetimesIrregular(1):minutes(5):datetimesIrregular(end);
            
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', 6);
            testCase.verifyEqual(length(validFlags), length(datetimesRegular));
        end
    end
end
