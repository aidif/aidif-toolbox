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


    methods (Test)
        
        function standardBolusAtMidnight(testCase)
            tt = timetable(testCase.startTime, 5, duration(0,0,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            ttResampled = AIDIF.interpolateBolus(tt);
            
            TestHelpers.verifyBaseInsulinDeliveryTable(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase, ttResampled);
            testCase.verifyEqual(height(ttResampled), 1);
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 5, 'Total insulin conserved');
            testCase.verifyEqual(ttResampled.InsulinDelivery(1), 5);
            testCase.verifyEqual(ttResampled.Time(1), testCase.startTime);
        end

        function standardBolusRoundsToClosest5Min(testCase)
            tt = timetable(testCase.startTime + minutes(7), 3, duration(0,0,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            ttResampled = AIDIF.interpolateBolus(tt);
            
            TestHelpers.verifyBaseInsulinDeliveryTable(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase, ttResampled);
            testCase.verifyEqual(height(ttResampled), 1);
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 3, 'Total insulin conserved');
            testCase.verifyEqual(ttResampled.Time(1), testCase.startTime + minutes(5));
        end

        function extendedBolus30MinEqualDistribution(testCase)
            tt = timetable(testCase.startTime, 6, duration(0,30,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            ttResampled = AIDIF.interpolateBolus(tt);
            
            TestHelpers.verifyBaseInsulinDeliveryTable(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase, ttResampled);
            testCase.verifyEqual(height(ttResampled), 6);
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 6, 'AbsTol', 1e-10);
            testCase.verifyEqual(ttResampled.InsulinDelivery, ones(6,1), 'AbsTol', 1e-10);
        end

        function extendedBolusPartialIntervals(testCase)
            tt = timetable(testCase.startTime + minutes(2), 10, duration(0,50,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            ttResampled = AIDIF.interpolateBolus(tt);
            
            TestHelpers.verifyBaseInsulinDeliveryTable(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase, ttResampled);
            testCase.verifyEqual(height(ttResampled), 11);
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 10, 'AbsTol', 1e-10);
            testCase.verifyEqual(ttResampled.InsulinDelivery(1), 0.6, 'AbsTol', 1e-10);
            testCase.verifyEqual(ttResampled.InsulinDelivery(end), 0.4, 'AbsTol', 1e-10);
            testCase.verifyEqual(ttResampled.InsulinDelivery(2:end-1), ones(9,1), 'AbsTol', 1e-10);
        end

        function mixedStandardAndExtendedBoluses(testCase)
            tt = timetable([testCase.startTime; testCase.startTime + minutes(15); testCase.startTime + minutes(45)], ...
                          [2; 3; 6], [duration(0,0,0); duration(0,10,0); duration(0,0,0)], ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            ttResampled = AIDIF.interpolateBolus(tt);
            
            TestHelpers.verifyBaseInsulinDeliveryTable(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase, ttResampled);
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 11, 'AbsTol', 1e-10);
            testCase.verifyEqual(ttResampled.InsulinDelivery(1), 2);
            testCase.verifyEqual(ttResampled.InsulinDelivery(10), 6);
        end

        function errorWhenExtendedOverlapsExtended(testCase)
            tt = timetable(testCase.startTime + hours([0,1]'), [1,1]', minutes([90,10]'), ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), AIDIF.Constants.ERROR_ID_OVERLAPPING_DELIVERIES);
        end

        function extendedBolusSpansCorrectIntervals(testCase)
            tt = timetable(testCase.startTime, 2, duration(0,7,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            ttResampled = AIDIF.interpolateBolus(tt);
            
            TestHelpers.verifyBaseInsulinDeliveryTable(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase, ttResampled);
            testCase.verifyEqual(height(ttResampled), 2);
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 2, 'AbsTol', 1e-10);
        end

        function errorOnInvalidBolusValue(testCase)
            tt = timetable(testCase.startTime, -1, seconds(0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE);
        end

        function errorOnInvalidDuration(testCase)
            tt = timetable(testCase.startTime, 5, duration(0,-5,0), ...
                'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), AIDIF.Constants.ERROR_ID_INVALID_VALUE_RANGE);
        end

        function errorOnMissingColumns(testCase)
            tt = timetable(testCase.startTime, 5, 'VariableNames', {'bolus'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), AIDIF.Constants.ERROR_ID_MISSING_COLUMN);
        end

        function errorOnDuplicates(testCase)
            tt = timetable(testCase.startTime + seconds([0,0])', [1, 2]', seconds([0,0])', ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), AIDIF.Constants.ERROR_ID_DUPLICATE_TIMESTAMPS);
        end

        function errorOnDuplicatedExtendedBoluses(testCase)
            tt = timetable(testCase.startTime + seconds([0,1,1,2])', [1, 2, 3, 4]', hours([0,1,1,0])', ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            testCase.verifyError(@() AIDIF.interpolateBolus(tt), AIDIF.Constants.ERROR_ID_DUPLICATE_TIMESTAMPS);
        end

        function noErrorOnStandardAndExtendedStartingSameTime(testCase)
            tt = timetable(testCase.startTime + seconds([0,1,1,2])', [1, 2, 3, 4]', hours([0,0,1,0])', ...
                          'VariableNames', {'bolus', 'delivery_duration'});
            AIDIF.interpolateBolus(tt);
        end

    end
end

