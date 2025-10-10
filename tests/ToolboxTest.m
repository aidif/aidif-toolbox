classdef ToolboxTest <  matlab.unittest.TestCase
% ToolboxTest - Unit test for testing the toolbox functions.


    methods (Test)
        function testToolboxDir(testCase)
            pathStr = AIDIF.toolboxdir();
            testCase.verifyClass(pathStr, 'char')
            testCase.verifyTrue(isfolder(pathStr))
        end

        function testToolboxVersion(testCase)
            versionStr = AIDIF.toolboxversion();
            testCase.verifyClass(versionStr, 'char')
            testCase.verifyTrue(startsWith(versionStr, 'Version'))
        end
    end
end
