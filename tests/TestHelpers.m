classdef TestHelpers
    properties (Constant)
        ERROR_ID_INVALID_ARGUMENT = "AIDIF:InvalidArgument"
    end
    
    methods(Static)
        function verifyTimeAlignmentTest(testCase,tt)
            timeDiffs = diff(tt.Time);
            testCase.verifyEqual(timeDiffs, minutes(5) * ones(size(timeDiffs)));
            testCase.verifyTrue(all(mod(tt.Time.Minute, 5)==0,'all'));
        end
    end
end
