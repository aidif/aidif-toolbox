%   Author: Michael Wheelock
%   Date: 2025-11-03
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved
classdef InterpolateCGMTest < matlab.unittest.TestCase
    properties
        cgmTT
    end

    methods (TestClassSetup)

        function SetupTestTimetable(testCase)
            datetimes = datetime("today") + minutes(0:5:60)';
            cgm = zeros(size(datetimes)) + 100;
            testCase.cgmTT = timetable(cgm,'RowTimes',datetimes);
        end
    end

    methods (Test)
        
        function TestTimeAlignment(testCase)
            % output table should always extend beyond irregular datetime start and end.
            expectedResult = timetable(zeros([14 1]) + 100,'RowTimes',datetime("today") + minutes(0:5:65)');
            offHourTT = testCase.cgmTT;

            % end sample should ceiling despite nearest to previous interval
            offHourTT.Time = offHourTT.Time + minutes(2);
            cgmResampled = AIDIF.interpolateCGM(offHourTT);
            verifyEqual(testCase,cgmResampled,expectedResult);

            % sample 1 should floor despite nearest to next interval
            offHourTT.Time = offHourTT.Time + minutes(2);
            cgmResampled = AIDIF.interpolateCGM(offHourTT);
            verifyEqual(testCase,cgmResampled,expectedResult);
        end

        function TestErrorsOnInputTable(testCase)
            missedVarName = testCase.cgmTT;
            missedVarName.Properties.VariableNames{'cgm'} = 'glucose';
            verifyError(testCase,@() AIDIF.interpolateCGM(missedVarName),TestHelpers.ERROR_ID_MISSING_COLUMN)

            unsorted = sortrows(testCase.cgmTT,'Time','descend');
            verifyError(testCase,@() AIDIF.interpolateCGM(unsorted),TestHelpers.ERROR_ID_UNSORTED_DATA)
            
        end

    end

end