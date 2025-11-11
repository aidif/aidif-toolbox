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
            start = datetime('today');
            datetimesIrregular = start + hours([0,1,2]);
            datetimesRegular   = start + hours([-.5, 0.5, 1.0, 1.5, 2.0, 2.5]);

            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(2), true);
            testCase.verifyEqual(actualFlags,[false,true,true,true,true,false]');

            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(2), false);
            testCase.verifyEqual(actualFlags, [false,true,true,true,false,false]');
        end

        function testNoGapUnalignedStartEarly(testCase)
            start = datetime("today");
            datetimesIrregular = start + minutes([2,7,12]');
            datetimesRegular = start + minutes([0,5,10]');
            actualFlags = AIDIF.findGaps(datetimesIrregular, datetimesRegular, minutes(5));
            testCase.verifyEqual(actualFlags, [false,true,true]');

        end

        function testNoGapUnalignedLate(testCase)
            start = datetime("today");
            datetimesIrregular = start + minutes([2,7,12]');
            datetimesRegular = start + minutes([5,10,15]');
            actualFlags = AIDIF.findGaps(datetimesIrregular, datetimesRegular, minutes(5));
            testCase.verifyEqual(actualFlags, [true,true,false]');
        end
        
        function testSimpleGapAligned(testCase)
            datetimesIrregular = datetime("today") +     hours([0, 1,    3, 4]); 
            datetimesRegular   = datetime("today") + hours([-1, 0, 1, 2, 3, 4, 5]);
            
            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1),true);
            testCase.verifyEqual(actualFlags, [false, true, true, false, true, true, false]'); 

            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1), false);
            testCase.verifyEqual(actualFlags, [false, true, false, false, true, false, false]'); 
        end
        
        function testSimpleGapUnaligned(testCase)
            datetimesIrregular = datetime("today") + hours([0, 1, 3, 4]); 
            datetimesRegular   = datetime("today") + hours([-0.9, 0.1, 1.1, 2.1, 3.1, 4.1, 5.1]);
            
            expectedFlags = [false, true, false, false, true, false, false]';
            
            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1),true);
            testCase.verifyEqual(actualFlags, expectedFlags); 

            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1),false);
            testCase.verifyEqual(actualFlags, expectedFlags); 
        end

        function testBoundary(testCase)
            datetimesIrregular = datetime("today") + minutes([10,15]); 
            datetimesRegular   = datetime("today") + minutes([9,10,11,14,15,16]);
            
            expectedFlags = [false,true,true,true,true,false]';
            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', minutes(10),true);
            testCase.verifyEqual(actualFlags, expectedFlags); 
            
            expectedFlags = [false,true,true,true,false,false]';
            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1),false);
            testCase.verifyEqual(actualFlags, expectedFlags); 
        end

        function testOnlyGaps(testCase)
            datetimesIrregular = datetime("today") + hours([0, 2, 4]);
            datetimesRegular = datetimesIrregular(1):minutes(30):datetimesIrregular(end);
            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1), true);
            testCase.verifyTrue(~any(actualFlags));
        end
    
        function testMultipleGaps(testCase)
            datetimesIrregular = datetime("today") + hours([0,1, 3,4, 6,7]);
            datetimesRegular = datetimesIrregular(1):minutes(30):datetimesIrregular(end);
            
            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1), true);
            testCase.verifyEqual(actualFlags,[true,true, ... %0-0:30
                                             true,false,false,false, ... %1:00-2:30
                                             true,true ...%3-3:30
                                             true,false,false,false, ... %4:00-5:30
                                             true, true, true ]'); %6-7:00

            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(1), false);
            testCase.verifyEqual(actualFlags,[true,true, ... %0-0:30
                                             false,false,false,false, ... %1:00-2:30
                                             true,true ...%3-3:30
                                             false,false,false,false, ... %4:00-5:30
                                             true, true, false ]'); %6-7:00

        end

        function testOutputLengthMatch(testCase)
            datetimesIrregular = datetime("today") + hours([0,1,2,3]);
            datetimesRegular = datetimesIrregular(1):minutes(5):datetimesIrregular(end);
            
            actualFlags = AIDIF.findGaps(datetimesIrregular', datetimesRegular', hours(6));
            testCase.verifyEqual(length(actualFlags), length(datetimesRegular));
        end
    end
end
