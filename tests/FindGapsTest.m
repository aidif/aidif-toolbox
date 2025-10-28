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
            % Original timetable with regular events less than maxGapHours
            ttTimes = datetime("today") + hours(0:1:3);
            tt = timetable(ttTimes', ones(length(ttTimes),1), 'VariableNames', {'basal_rate'});
            
            % Resample every 5 minutes
            resampledTimes = ttTimes(1):minutes(5):ttTimes(end);
            ttResampled = timetable(resampledTimes');
            
            ttValid = AIDIF.findGaps(tt, ttResampled, 6);
            
            % All values should be valid
            testCase.verifyTrue(all(ttValid.valid));
            
            % Row times should match resampled timetable
            testCase.verifyEqual(ttValid.Time, ttResampled.Time);
        end

        function testAllGaps(testCase)
            % Original timetable where all intervals exceed maxGapHours
            ttTimes = datetime("today") + hours([0, 10, 20]); % gaps > 6 hours
            tt = timetable(ttTimes', ones(length(ttTimes),1), 'VariableNames', {'basal_rate'});
            
            %resample
            resampledTimes = ttTimes(1):minutes(15):ttTimes(end);
            ttResampled = timetable(resampledTimes');
            
            ttValid = AIDIF.findGaps(tt, ttResampled, 6);
            
            % All resampled rows should be invalid except the last one
            testCase.verifyTrue(all(ttValid.valid(1:end-1)==false));
            testCase.verifyTrue(ttValid.valid(end));
        end

        function testSingleGap(testCase)
            % Original timetable with a gap > maxGapHours
            ttTimes = datetime("today") + hours([0, 1, 8, 9]); % 1-hr then 6-hr gap
            tt = timetable(ttTimes', ones(length(ttTimes),1), 'VariableNames', {'basal_rate'});
            
            resampledTimes = ttTimes(1):minutes(5):ttTimes(end);
            ttResampled = timetable(resampledTimes');
            
            ttValid = AIDIF.findGaps(tt, ttResampled, 6);
            
            % Check: first two intervals valid, gap interval invalid, then valid again
            gapStart = find(ttResampled.Time == ttTimes(2)); % after second event
            gapEnd   = find(ttResampled.Time < ttTimes(3), 1, 'last');
            testCase.verifyTrue(all(ttValid.valid(1:gapStart-1))); % before gap
            testCase.verifyFalse(any(ttValid.valid(gapStart:gapEnd))); % gap period
        end

        function testMultipleGaps(testCase)
            % Timetable with multiple gaps exceeding maxGapHours
            ttTimes = datetime("today") + hours([0,1, 4,5, 8]);
            tt = timetable(ttTimes', ones(length(ttTimes),1), 'VariableNames', {'basal_rate'});
            
            resampledTimes = ttTimes(1):minutes(30):ttTimes(end);
            ttResampled = timetable(resampledTimes');
            
            ttValid = AIDIF.findGaps(tt, ttResampled, 2);
            
            % Check that periods between 1-7 and 8-14 hours are invalid
            gap1Start = find(ttResampled.Time > ttTimes(2), 1)-1;
            gap1End   = find(ttResampled.Time < ttTimes(3), 1, 'last');
            testCase.verifyFalse(any(ttValid.valid(gap1Start:gap1End)));
            
            gap2Start = find(ttResampled.Time > ttTimes(4), 1)-1;
            gap2End   = find(ttResampled.Time < ttTimes(5), 1, 'last');
            testCase.verifyFalse(any(ttValid.valid(gap2Start:gap2End)));
        end

        function testOutputTimesMatch(testCase)
            % Check that output timestamps match resampled timetable exactly
            ttTimes = datetime("today") + hours([0,1,2,3]);
            tt = timetable(ttTimes', ones(length(ttTimes),1), 'VariableNames', {'basal_rate'});
            resampledTimes = ttTimes(1):minutes(5):ttTimes(end);
            ttResampled = timetable(resampledTimes');
            
            ttValid = AIDIF.findGaps(tt, ttResampled, 6);
            
            testCase.verifyEqual(ttValid.Time, ttResampled.Time);
        end
    end
end