%   Author: Jan Wrede
%   Date: 2025-10-22
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) year, AIDIF
%   All rights reserved

classdef InterpolateBasalTest <  matlab.unittest.TestCase
    methods
        function outputFormatTest(testCase, tt_resampled)
            % Check if the output is a timetable
            testCase.verifyTrue(istimetable(tt_resampled));
            
            % Check if the timetable has one column named 'InsulinDelivery'
            testCase.verifyEqual(tt_resampled.Properties.VariableNames, {'InsulinDelivery'});
            
            % Check if the times are 5 minutes apart
            timeDiffs = diff(tt_resampled.Time);
            testCase.verifyEqual(timeDiffs, minutes(5) * ones(size(timeDiffs)), 'All time intervals should be 5 minutes');

            %check if 5 minute intervals are aligned to the full hour
            testCase.verifyTrue(all(mod(tt_resampled.Time.Minute, 5)==0,'all'), 'Times should be aligned to the nearest 5 minutes');
        end
    end
    
    methods (Test)
        
        function singleValueError(testCase)
            % Test case for a single value input that should throw an error
            tt = timetable(datetime('today'), 1, 'VariableNames', {'basal_rate'});
            testCase.verifyError(@() AIDIF.interpolateBasal(tt), 'AIDIF:InvalidInput');
        end

        function zeroRate(testCase)
            tt = timetable(datetime('today') + minutes([0;15]), [0;100], 'VariableNames', {'basal_rate'});
            tt_resampled = AIDIF.interpolateBasal(tt);
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 3);
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 0)
        end

        function oneHourFixedPerfectlyAligned(testCase)
            % 1 U/h from 00:00:00 to 01:00:00
            tt = timetable(datetime('today') + hours([0;1]), [1;0], 'VariableNames', {'basal_rate'});
            tt_resampled = AIDIF.interpolateBasal(tt);
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 12)
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 1, 'AbsTol',1e-10)
            testCase.verifyEqual(tt_resampled.InsulinDelivery, repmat(5/60,12,1), 'AbsTol',1e-8)
            testCase.verifyEqual(tt_resampled.Time(end), datetime('today')+minutes(55))
        end

        function oneHourFixedImperfectlyAligned(testCase)
            % 1 U/h from 00:02:00 to 01:02:00
            tt = timetable(datetime('today') + minutes(2) + hours([0;1]), [1;0], 'VariableNames', {'basal_rate'});
            tt_resampled = AIDIF.interpolateBasal(tt);
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 13)
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 1, 'AbsTol',1e-10)
            testCase.verifyEqual(tt_resampled.InsulinDelivery([1,end]), [3/60; 2/60], 'AbsTol',1e-10)
            testCase.verifyEqual(tt_resampled.Time(end), datetime('today')+minutes(60))
        end

        function SquareWaveOnOffOnOff(testCase)
            %basal rate changes from 1->0->1->0 every hour
            tt = timetable(datetime('today') + hours([0,1,2,3,4]'), [1,0,1,0,1]', 'VariableNames', {'basal_rate'});
            tt_resampled = AIDIF.interpolateBasal(tt);
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 48)
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 2, 'AbsTol',1e-10)
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery(13:24)), 0, 'AbsTol',1e-10)
        end

        function StartStopWithin5Minutes(testCase)
            %basal rate changes multiple times within 5 minutes
            tt = timetable(datetime('today') + minutes([1, 12,14,  23,27]'), [0, 1,0, 1,0]', 'VariableNames', {'basal_rate'});
            tt_resampled = AIDIF.interpolateBasal(tt);
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 6)
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 3 * 2/60, 'AbsTol',1e-10)
            testCase.verifyEqual(tt_resampled.Time(end), datetime('today')+minutes(25))
            testCase.verifyEqual(tt_resampled.InsulinDelivery, [0,0,2/60,0,2/60,2/60]', 'AbsTol',1e-10)
        end
    end
end
