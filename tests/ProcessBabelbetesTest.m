classdef ProcessBabelbetesTest < matlab.unittest.TestCase

    methods (Test)

  
        function testSuccessfulProcessData(testCase)
            testPath = string(what("tests\assets\").path);
            outputPath = string(what("tests\outputs\").path);
            
            AIDIF.processBabelbetes(testPath,"exportPath" ,outputPath);

            outputDir = AIDIF.constructHiveQueryTable(outputPath);
            
            testCase.verifyTrue(isfile(outputDir.path));
            combinedTT = parquetread(outputDir.path, "OutputType", "timetable");
            testCase.verifyNotEmpty(combinedTT, "Missing output combined data parquet file");
            testCase.verifyNotEmpty(combinedTT.egv, "Missing EVG data");
            testCase.verifyNotEmpty(combinedTT.totalInsulin, "Missing totalInsulin data");
            testCase.verifyNotEmpty(combinedTT.datetime, "Missing datetime data");
        end
    end
end
