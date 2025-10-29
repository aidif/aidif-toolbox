%   Author: Jan Wrede
%   Date: 2025-10-29
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

classdef InterpolateBolusTest < matlab.unittest.TestCase

    properties
        startTime
    end

    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.startTime = datetime('today');
        end
    end

    methods
        function outputFormatTest(testCase, tt)
            testCase.verifyTrue(istimetable(tt));
            testCase.verifyEqual(tt.Properties.VariableNames, {'InsulinDelivery'});
            
            % 5-minute intervals
            timeDiffs = diff(tt.Time);
            testCase.verifyEqual(timeDiffs, minutes(5) * ones(size(timeDiffs)));

            % Aligned to 5-minute marks
            testCase.verifyTrue(all(mod(tt.Time.Minute, 5)==0,'all'));
        end
    end

    methods (Test)
        
        function standardBolusAtMidnight(testCase)
            tt = timetable(testCase.startTime, 5, duration(0,0,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            tt_resampled = AIDIF.interpolateBolus(tt);
            
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 1);
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 5, 'Total insulin conserved');
            testCase.verifyEqual(tt_resampled.InsulinDelivery(1), 5);
            testCase.verifyEqual(tt_resampled.Time(1), testCase.startTime);
        end

        function standardBolusRoundsToClosest5Min(testCase)
            tt = timetable(testCase.startTime + minutes(7), 3, duration(0,0,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            tt_resampled = AIDIF.interpolateBolus(tt);
            
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 1);
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 3, 'Total insulin conserved');
            testCase.verifyEqual(tt_resampled.Time(1), testCase.startTime + minutes(5));
        end

        function extendedBolus30MinEqualDistribution(testCase)
            tt = timetable(testCase.startTime, 6, duration(0,30,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            tt_resampled = AIDIF.interpolateBolus(tt);
            
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 6);
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 6, 'AbsTol', 1e-10);
            testCase.verifyEqual(tt_resampled.InsulinDelivery, ones(6,1), 'AbsTol', 1e-10);
        end

        function extendedBolusPartialIntervals(testCase)
            tt = timetable(testCase.startTime + minutes(2), 10, duration(0,50,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            tt_resampled = AIDIF.interpolateBolus(tt);
            
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 11);
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 10, 'AbsTol', 1e-10);
            testCase.verifyEqual(tt_resampled.InsulinDelivery(1), 0.6, 'AbsTol', 1e-10);
            testCase.verifyEqual(tt_resampled.InsulinDelivery(end), 0.4, 'AbsTol', 1e-10);
            testCase.verifyEqual(tt_resampled.InsulinDelivery(2:end-1), ones(9,1), 'AbsTol', 1e-10);
        end

        function mixedStandardAndExtendedBoluses(testCase)
            tt = timetable([testCase.startTime; testCase.startTime + minutes(15); testCase.startTime + minutes(45)], ...
                          [2; 3; 6], [duration(0,0,0); duration(0,10,0); duration(0,0,0)], ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            tt_resampled = AIDIF.interpolateBolus(tt);
            
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 11, 'AbsTol', 1e-10);
            testCase.verifyEqual(tt_resampled.InsulinDelivery(1), 2);
            testCase.verifyEqual(tt_resampled.InsulinDelivery(10), 6);
        end

        
        function standardOverlapsExtended(testCase)
            tt = timetable(testCase.startTime + hours([0,1]'), [1,1]', minutes([90,0]'), ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), 'AIDIF:InvalidInput:BolusesOverlap');
            
        end

        function extendedOverlapsExtended(testCase)
            tt = timetable(testCase.startTime + hours([0,1]'), [1,1]', minutes([90,10]'), ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), 'AIDIF:InvalidInput:BolusesOverlap');
            
        end

        function extendedBolusSpansCorrectIntervals(testCase)
            tt = timetable(testCase.startTime, 2, duration(0,7,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            tt_resampled = AIDIF.interpolateBolus(tt);
            
            outputFormatTest(testCase, tt_resampled);
            testCase.verifyEqual(height(tt_resampled), 2);
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 2, 'AbsTol', 1e-10);
        end

        function outputTest(testCase)
            tt = timetable(testCase.startTime + hours([10,30,38,50]') + minutes([0,1,1,2.5]'), ...
                          [5,7,5,4]', hours([0,5,0,1]'), ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            tt_resampled = AIDIF.interpolateBolus(tt);
            outputFormatTest(testCase, tt_resampled);
        end

        function duplicatedEntries(testCase)
            tt = timetable(testCase.startTime + minutes([3,3])', [1, 2]', seconds([0,0])', ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), 'AIDIF:InvalidInput:ContainsDuplicates');
        end

        function invalidBolusValueError(testCase)
            tt = timetable(testCase.startTime, 0, duration(0,0,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), 'AIDIF:InvalidInput:InvalidValue');
        end

        function invalidDurationError(testCase)
            tt = timetable(testCase.startTime, 5, duration(0,-5,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), 'AIDIF:InvalidInput:NegativeDurations');
        end

        function missingColumnsError(testCase)
            tt = timetable(testCase.startTime, 5, 'VariableNames', {'bolus'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), 'AIDIF:InvalidInput:InvalidColumns');
        end

    end

end