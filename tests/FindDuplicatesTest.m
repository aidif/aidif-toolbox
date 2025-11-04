%   Author: Jan Wrede
%   Date: 2025-10-29
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

classdef FindDuplicatesTest < matlab.unittest.TestCase

    properties
        startTime
    end

    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.startTime = datetime("today");
        end
    end

    methods (Test)
        
        function noDuplicatesReturnsFalse(testCase)
            tt = timetable([testCase.startTime; testCase.startTime + minutes(5); testCase.startTime + minutes(10)], ...
                          [1; 2; 3], 'VariableNames', {'data'});
            actualResult = AIDIF.findDuplicates(tt);
            expectedResult = false(3,1);
            testCase.verifyEqual(actualResult, expectedResult);
        end

        function allDuplicatesReturnTrue(testCase)
            tt = timetable([testCase.startTime; testCase.startTime; testCase.startTime], ...
                          [1; 1; 1], 'VariableNames', {'data'});
            actualResult = AIDIF.findDuplicates(tt);
            expectedResult = true(3,1);
            testCase.verifyEqual(actualResult, expectedResult);
        end

        function mixedDuplicatesCorrectlyIdentified(testCase)
            times = [testCase.startTime; testCase.startTime + minutes(5); testCase.startTime; testCase.startTime + minutes(10)];
            tt = timetable(times, [1; 2; 1; 4], 'VariableNames', {'data'});
            actualResult = AIDIF.findDuplicates(tt);
            expectedResult = [true; false; true; false];
            testCase.verifyEqual(actualResult, expectedResult);
        end

        function singleRowReturnsFalse(testCase)
            tt = timetable(testCase.startTime, 5, 'VariableNames', {'data'});
            actualResult = AIDIF.findDuplicates(tt);
            expectedResult = false;
            testCase.verifyEqual(actualResult, expectedResult);
        end

        function duplicatedRowTimesAreTrue(testCase)
            tt = timetable(testCase.startTime+minutes([1,2,3,2,5,6,1,8]'), [1,2,3,4,5,6,7,8]', 'VariableNames', {'data'});
            actualResult = AIDIF.findDuplicates(tt(:,[]));
            expectedResult = [true,true,false,true,false,false,true,false]';
            testCase.verifyEqual(actualResult, expectedResult);
        end
    end
end
