classdef ConstructHiveQueryTableTest < matlab.unittest.TestCase
    properties
        testRoot
        partitionData
        fullPaths
    end

    methods (TestMethodSetup)

        function createHivePartition(testCase)
            % Shared setup for the entire test class
            testCase.testRoot = fullfile(tempdir, 'HiveTest');
            mkdir(testCase.testRoot);

            % Define test file paths directly
            filePaths = fullfile(testCase.testRoot, ...
                ["study_name=ABC/data_type=D/patient_id=101/file1.parquet", ...
                "study_name=ABC/data_type=D/patient_id=102/file2.parquet", ...
                "study_name=XYZ/data_type=E/patient_id=201/file3.parquet"]);

            for i = 1:length(filePaths)
                [directoryPath, ~, ~] = fileparts(filePaths(i));
                mkdir(directoryPath);
                fid = fopen(filePaths(i), 'w');
                if fid ~= -1
                    fclose(fid);
                else
                    error('Could not create test file: %s', fullFile);
                end
            end

            % Convert to a string array for convenient testing
            testCase.fullPaths = string(filePaths)';

            testCase.addTeardown(@() rmdir(testCase.testRoot,"s"));
        end
    end

    methods (Test)

        function correctHiveSubfolders(testCase)
            queryTable = AIDIF.constructHiveQueryTable(testCase.testRoot);
            for i = 1:numel(testCase.fullPaths)
            testCase.verifySubstring(string(queryTable.path(i)),testCase.fullPaths(i));
            end
        end

        function correctTableVariablesMade(testCase)
            queryTable = AIDIF.constructHiveQueryTable(testCase.testRoot);
            
            expectedVarNames = ["study_name" "data_type" "patient_id" "path"];
            expectedRowValues = ["ABC" "D" "101";...
                                 "ABC" "D" "102";...
                                 "XYZ" "E" "201"];
            verifyEqual(testCase,string(queryTable.Properties.VariableNames),...
                          expectedVarNames);
            verifyEqual(testCase,queryTable{:,1:end-1},expectedRowValues);
        end

        function errorOnTrailingSeparator(testCase)
            testRootWithSep = testCase.testRoot;
            testRootWithSep = fullfile(testRootWithSep, filesep);
            
            verifyError(testCase,@() AIDIF.constructHiveQueryTable(testRootWithSep), ...
                AIDIF.Constants.ERROR_ID_INVALID_PATH_FORMAT);

        end

        function errorOnInconsistentSchema(testCase)
            % Case: detached path missing a partition level
            shortPath = fullfile(testCase.testRoot,...
                "study_name=XYZ/patient_id=202/file4.parquet");

            mkdir(fileparts(shortPath))
            fid = fopen(shortPath, 'w');
            if fid ~= -1
                fclose(fid);
            else
                error('Could not create test file: %s', shortPath);
            end

            verifyError(testCase,@() AIDIF.constructHiveQueryTable(testCase.testRoot),...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE);
            rmdir(fileparts(shortPath),'s');

            % Case: detached path with additional partition level
            longPath = fullfile(testCase.testRoot,...
                "study_name=XYZ/data_type=E/patient_id=203/session_id=5/file5.parquet");
            mkdir(fileparts(longPath))
            fid = fopen(longPath, 'w');
            if fid ~= -1
                fclose(fid);
            else
                error('Could not create test file: %s', shortPath);
            end

            verifyError(testCase,@() AIDIF.constructHiveQueryTable(testCase.testRoot),...
                AIDIF.Constants.ERROR_ID_INCONSISTENT_STRUCTURE);
            rmdir(fileparts(longPath),'s');
        end

    end
end
