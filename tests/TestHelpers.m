classdef TestHelpers
    methods(Static)
        function verifyTimeAlignmentTest(testCase,tt)
            timeDiffs = diff(tt.Time);
            testCase.verifyEqual(timeDiffs, minutes(5) * ones(size(timeDiffs)));
            testCase.verifyTrue(all(mod(tt.Time.Minute, 5)==0,'all'));
        end
        
        function verifyBaseInsulinDeliveryTable(testCase, tt)
            testCase.verifyTrue(istimetable(tt));
            testCase.verifyEqual(tt.Properties.VariableNames, {'InsulinDelivery'});
        end

    end
end
