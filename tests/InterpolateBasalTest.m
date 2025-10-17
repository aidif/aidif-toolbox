classdef InterpolateBasalTest <  matlab.unittest.TestCase

    methods (Test)

        function oneHourConstant(testCase)
            tt = timetable(datetime('today')+hours([0;1]), [1;0], 'VariableNames', {'basal_rate'});
            tt_resampled = AIDIF.interpolateBasal(tt);
            testCase.verifyEqual(height(tt_resampled), 13)
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 1, 'AbsTol',1e-10)
            testCase.verifyEqual(tt_resampled.InsulinDelivery([1,end]), [5/60;0])
        end

        function uneven(testCase)
            tt = timetable(datetime('today')+seconds([-150;+150]), [1;0], 'VariableNames', {'basal_rate'});
            tt_resampled = AIDIF.interpolateBasal(tt);
            testCase.verifyEqual(height(tt_resampled), 2)
            testCase.verifyEqual(sum(tt_resampled.InsulinDelivery), 5/60, 'AbsTol',1e-10)
            %testCase.verifyEqual(tt_resampled.InsulinDelivery, [2.5/60,2.5/60], 'AbsTol',1e-10)
        end

        function perfectlyAlignedValues(testCase)
            n=12;
            dt = datetime('today')+minutes((0:5:5*(n-1))');
            basal_rate = ones(n,1); basal_rate(2:2:end)=0;
            %basal_rate(end)=1;

            tt = timetable(dt, basal_rate);
            tt_resampled = AIDIF.interpolateBasal(tt);
            
            %stem(tt.Properties.RowTimes,tt.basal_rate); hold on
            %stem(tt_resampled.Properties.RowTimes,tt.basal_rate,'--','Color','red','DisplayName','resampled')
            %hold off

            
            testCase.verifyEqual(tt.Properties.RowTimes, tt_resampled.Properties.RowTimes) % dt already was in 5 minute spacing
            deliveries_expected = basal_rate*5/60;
            deliveries_expected(end) = 0; % last rate didn't start delivery yet

            testCase.verifyEqual(tt_resampled.InsulinDelivery, deliveries_expected ,'AbsTol',1e-10)
            testCase.verifyEqual(sum(deliveries_expected), 0.5, 'AbsTol',1e-10) %6 times
            
        end
    end
end
