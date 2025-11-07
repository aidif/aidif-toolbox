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
        function firstRegularSampleBeforeIrregular(testCase)
            start = datetime("today");
            datetimesIrregular = start + minutes([2,7,12]');
            datetimesRegular = start + minutes([0,5,10]');
            validFlags = AIDIF.findGaps(datetimesIrregular, datetimesRegular, minutes(5));
            testCase.verifyEqual(validFlags, [false,true,true]');
        end

        function firstRegularSampleAfterIrregular(testCase)
            start = datetime("today");
            datetimesIrregular = start + minutes([2,7,12]');
            datetimesRegular = start + minutes([5,10,15]');
            validFlags = AIDIF.findGaps(datetimesIrregular, datetimesRegular, minutes(5));
            testCase.verifyEqual(validFlags, [true,true,false]');
        end

        function outsideRanges(testCase)
            start = datetime("today");
            datetimesIrregular = start + minutes([100,105]');
            datetimesRegular = start + minutes([0,99, 100,102,105,110, 111]');
            validFlags = AIDIF.findGaps(datetimesIrregular, datetimesRegular, minutes(5));
            testCase.verifyEqual(validFlags, [false, false, true, true, true, false, false]');
        end

        function testNoGaps(testCase)
            datetimesIrregular = datetime("today") + hours(0:1:3);
            datetimesRegular = datetimesIrregular(1):minutes(30):datetimesIrregular(end);
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(2));
            testCase.verifyTrue(all(validFlags));
        end

        function testAllGapsPerfectAligned(testCase)
            datetimesIrregular = datetime("today") + hours([0, 2, 4]);
            datetimesRegular = datetimesIrregular(1):minutes(30):datetimesIrregular(end);
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1));
            testCase.verifyEqual(validFlags, [true, false, false, false, true, false, false, false, true]');
        end

        function testAllGaps(testCase)
            datetimesIrregular = datetime("today") + hours([0, 2, 4]);
            datetimesRegular   = datetimesIrregular(1)+seconds(1):minutes(30):datetimesIrregular(end);
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1));
            testCase.verifyTrue(all(validFlags==false));
        end

        function testSimpleGap(testCase)
            datetimesIrregular = datetime("today") + hours([0, 1, 2, 4, 5]); 
            datetimesRegular = datetimesIrregular(1):hours(1):datetimesIrregular(end);
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1));
            testCase.verifyEqual(validFlags,[true,true,true,false,true,true]'); 
        end
    
        function testMultipleGaps(testCase)
            datetimesIrregular = datetime("today") + hours([0,1, 3,4, 6,7]);
            datetimesRegular = datetimesIrregular(1):minutes(30):datetimesIrregular(end);
            
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1));
            
            testCase.verifyEqual(validFlags,[true,true,true, ... %0-1:00
                                             false,false,false, ... %1:30-2:30
                                             true,true,true ...%3-4:00
                                             false,false,false, ... %4:30-5:30
                                             true, true, true ]'); %6-7:00

        end

        function testOutputLengthMatch(testCase)
            datetimesIrregular = datetime("today") + hours([0,1,2,3]);
            datetimesRegular = datetimesIrregular(1):minutes(5):datetimesIrregular(end);
            
            validFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(6));
            testCase.verifyEqual(length(validFlags), length(datetimesRegular));
        end
    end
end
