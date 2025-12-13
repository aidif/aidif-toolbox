classdef ProcessBabelbetesTest < matlab.unittest.TestCase
    properties
        testPath = fullfile(pwd,"assets");
        outputPath = fullfile(pwd,"outputs");
    end

    methods (Access = private)

        function removeOutputDirectory(testCase)
            if exist(testCase.outputPath,"dir") == 7
                rmdir(testCase.outputPath,'s')
            end
        end
    end
    
    methods (TestMethodSetup)

        function resetOutputDir(testCase)
            % clear 'outputs' directory before and after any test.
            testCase.removeOutputDirectory();
            testCase.addTeardown(@() testCase.removeOutputDirectory());
        end
    end
    
    methods (Test)

  
        function successfulProcessForAllData(testCase)
            
            AIDIF.processBabelbetes(testCase.testPath,"exportPath" ,testCase.outputPath);

            outputDir = AIDIF.constructHiveQueryTable(testCase.outputPath);
            
            testCase.verifyEqual(height(outputDir),4);
            testCase.verifyTrue(isfile(outputDir.path(1)));

            combinedTT = parquetread(outputDir.path(1), "OutputType", "timetable");
            testCase.verifyNotEmpty(combinedTT, "Missing output combined data parquet file");
            testCase.verifyNotEmpty(combinedTT.egv, "Missing EVG data");
            testCase.verifyNotEmpty(combinedTT.totalInsulin, "Missing totalInsulin data");
            testCase.verifyNotEmpty(combinedTT.datetime, "Missing datetime data");
        end

        function successfulProcessWithPatientSubset(testCase)
            patientTable = AIDIF.constructHiveQueryTable(testCase.testPath);
            [~,patientTable] = findgroups(patientTable(:,["study_name" "patient_id"]));
            patientTable = patientTable(patientTable.study_name == "StudyB" & patientTable.patient_id == "Patient2",:);

            AIDIF.processBabelbetes(testCase.testPath,"exportPath",testCase.outputPath,"patientTable",patientTable);

            outputDir = AIDIF.constructHiveQueryTable(testCase.outputPath);

            testCase.verifyEqual(height(outputDir),1);
            testCase.verifyEqual(outputDir.study_name,"StudyB");
            testCase.verifyEqual(outputDir.patient_id,"Patient2")
            testCase.verifyTrue(isfile(outputDir.path(1)));

            combinedTT = parquetread(outputDir.path(1), "OutputType", "timetable");
            testCase.verifyNotEmpty(combinedTT, "Missing output combined data parquet file");
            testCase.verifyNotEmpty(combinedTT.egv, "Missing EVG data");
            testCase.verifyNotEmpty(combinedTT.totalInsulin, "Missing totalInsulin data");
            testCase.verifyNotEmpty(combinedTT.datetime, "Missing datetime data");
        end
    end
end
