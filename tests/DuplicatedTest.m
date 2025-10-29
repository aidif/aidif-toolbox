%   Author: Jan Wrede
%   Date: 2025-10-29
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

classdef DuplicatedTest < matlab.unittest.TestCase

    properties
        startTime
    end

    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.startTime = datetime('today');
        end
    end

    methods (Test)
        
        function noDuplicatesReturnsFalse(testCase)
            % No duplicates should return all false
            tt = timetable([testCase.startTime; testCase.startTime + minutes(5); testCase.startTime + minutes(10)], ...
                          [1; 2; 3], 'VariableNames', {'data'});
            result = AIDIF.duplicated(tt);
            
            testCase.verifyEqual(result, false(3,1));
        end

        function allDuplicatesReturnTrue(testCase)
            % All rows with same timestamp should return true
            tt = timetable([testCase.startTime; testCase.startTime; testCase.startTime], ...
                          [1; 1; 1], 'VariableNames', {'data'});
            result = AIDIF.duplicated(tt);
            
            testCase.verifyEqual(result, true(3,1));
        end

        function mixedDuplicatesCorrectlyIdentified(testCase)
            % Mixed scenario with some duplicates and some unique
            times = [testCase.startTime; testCase.startTime + minutes(5); testCase.startTime; testCase.startTime + minutes(10)];
            tt = timetable(times, [1; 2; 1; 4], 'VariableNames', {'data'});
            result = AIDIF.duplicated(tt);
            
            expected = [true; false; true; false];
            testCase.verifyEqual(result, expected);
        end

        function singleRowReturnsFalse(testCase)
            % Single row cannot be duplicated
            tt = timetable(testCase.startTime, 5, 'VariableNames', {'data'});
            result = AIDIF.duplicated(tt);
            
            testCase.verifyEqual(result, false);
        end

        function duplicatedRowTimesAreTrue(testCase)
            % Single row cannot be duplicated
            tt = timetable(testCase.startTime+minutes([1,2,3,2,5,6,1,8]'), [1,2,3,4,5,6,7,8]', 'VariableNames', {'data'});
            result = AIDIF.duplicated(tt(:,[]));
            
            testCase.verifyEqual(result, [true,true,false,true,false,false,true,false]');
        end


    end

end