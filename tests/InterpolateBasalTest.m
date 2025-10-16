classdef InterpolateBasalTest <  matlab.unittest.TestCase

    methods (Test)
        function perfectlyAlignedValues(testCase)
            n=12;
            minutes = (0:5:5*(n-1))';
            dt = minutes/(24*60);
            br = ones(n,1); br(2:2:end-1)=0;
            [dti,U] = AIDIF.interpolateBasal( dt,br);
            
            testCase.verifyEqual(dti,dt) % dt already was in 5 minute spacing
            U_expected = br*5/60; % each rate (1U/h) is 5 minutes long
            U_expected(end) = 0; % last rate didn't start delivery yet
            testCase.verifyEqual(U,U_expected,'AbsTol',1e-10)
            testCase.verifyEqual(sum(U), 0.5, 'AbsTol',1e-10) %6 times
            
        end
    end
end
