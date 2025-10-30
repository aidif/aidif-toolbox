%   Author: Jan Wrede
%   Date: 2025-10-22
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

classdef InterpolateBasalTest <  matlab.unittest.TestCase
    methods
        function outputFormatTest(testCase, tt)
            testCase.verifyTrue(istimetable(tt));
            testCase.verifyEqual(tt.Properties.VariableNames, {'InsulinDelivery'});
        end
    end
    methods (Test)
        function singleValueError(testCase)
            tt = timetable(datetime('today'), 1, 'VariableNames', {'basal_rate'});
            testCase.verifyError(@() AIDIF.interpolateBasal(tt), TestHelpers.ERROR_ID_INVALID_ARGUMENT);
        end

        function zeroRate(testCase)
            tt = timetable(datetime('today') + minutes([0;15]), [0;100], 'VariableNames', {'basal_rate'});
            ttResampled = AIDIF.interpolateBasal(tt);
            
            outputFormatTest(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase,ttResampled)
            
            testCase.verifyEqual(height(ttResampled), 3);
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 0)
        end

        function oneHourFixedPerfectlyAligned(testCase)
            tt = timetable(datetime('today') + hours([0;1]), [1;0], 'VariableNames', {'basal_rate'});
            ttResampled = AIDIF.interpolateBasal(tt);
            
            outputFormatTest(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase,ttResampled)

            testCase.verifyEqual(height(ttResampled), 12)
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 1, 'AbsTol',1e-10)
            testCase.verifyEqual(ttResampled.InsulinDelivery, repmat(5/60,12,1), 'AbsTol',1e-8)
            testCase.verifyEqual(ttResampled.Time(end), datetime('today')+minutes(55))
        end

        function oneHourFixedImperfectlyAligned(testCase)
            tt = timetable(datetime('today') + minutes(2) + hours([0;1]), [1;0], 'VariableNames', {'basal_rate'});
            ttResampled = AIDIF.interpolateBasal(tt);
            
            outputFormatTest(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase,ttResampled)

            testCase.verifyEqual(height(ttResampled), 13)
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 1, 'AbsTol',1e-10)
            testCase.verifyEqual(ttResampled.InsulinDelivery([1,end]), [3/60; 2/60], 'AbsTol',1e-10)
            testCase.verifyEqual(ttResampled.Time(end), datetime('today')+minutes(60))
        end

        function squareWaveOnOffOnOff(testCase)
            tt = timetable(datetime('today') + hours([0,1,2,3,4]'), [1,0,1,0,1]', 'VariableNames', {'basal_rate'});
            ttResampled = AIDIF.interpolateBasal(tt);
            
            outputFormatTest(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase,ttResampled)
            
            testCase.verifyEqual(height(ttResampled), 48)
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 2, 'AbsTol',1e-10)
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery(13:24)), 0, 'AbsTol',1e-10)
        end

        function startStopWithin5Minutes(testCase)
            tt = timetable(datetime('today') + minutes([1, 12,14,  23,27]'), [0, 1,0, 1,0]', 'VariableNames', {'basal_rate'});
            ttResampled = AIDIF.interpolateBasal(tt);
            
            outputFormatTest(testCase, ttResampled);
            TestHelpers.verifyTimeAlignmentTest(testCase,ttResampled)
            
            testCase.verifyEqual(height(ttResampled), 6)
            testCase.verifyEqual(sum(ttResampled.InsulinDelivery), 3 * 2/60, 'AbsTol',1e-10)
            testCase.verifyEqual(ttResampled.Time(end), datetime('today')+minutes(25))
            testCase.verifyEqual(ttResampled.InsulinDelivery, [0,0,2/60,0,2/60,2/60]', 'AbsTol',1e-10)
        end
    end
end
