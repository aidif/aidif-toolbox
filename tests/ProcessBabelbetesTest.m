classdef ProcessBabelbetesTest < matlab.unittest.TestCase

    methods (Test)

  
        function testSuccessfulProcessData(testCase)
            testQT = DataHelper.getHiveQueryTable("default_inputs");
                
            processBabelbetes(DataHelper.DefaultDataAssestDir,"exportPath" ,DataHelper.DefaultDataOutputDir,"queryTable", testQT);

            outputPath = DataHelper.getCombinedOutputFullPath(DataHelper.DefaultDataOutputDir);
            
            testCase.assertEqual(exist(outputPath, "file"), 2);
            combinedTT = parquetread(outputPath, "OutputType", "timetable");
            testCase.verifyNotEmpty(combinedTT, "Missing output combined data parquet file");
            testCase.verifyNotEmpty(combinedTT.egv, "Missing EVG data");
            testCase.verifyNotEmpty(combinedTT.totalInsulin, "Missing totalInsulin data");
            testCase.verifyNotEmpty(combinedTT.datetime, "Missing datetime data");
           
        end
    end
end
