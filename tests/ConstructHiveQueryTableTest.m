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

            %create folders and parquet files
            for i = 1:length(filePaths)
                [directoryPath, ~, ~] = fileparts(filePaths(i));
                mkdir(directoryPath)
                fid = fopen(filePaths(i), 'w');
                if fid ~= -1
                    fclose(fid);
                else
                    error('Could not create test file: %s', fullFile);
                end
            end

            % Convert to a string array for convenient testing
            testCase.fullPaths = string(filePaths)';

            testCase.addTeardown(@() rmdir(testCase.testRoot,"s"))
        end
    end

    methods (Test)

        function correctHiveSubfolders(testCase)
            queryTable = AIDIF.constructHiveQueryTable(testCase.testRoot);
            for i = 1:numel(testCase.fullPaths)
            testCase.verifySubstring(string(queryTable.path(i)),testCase.fullPaths(i))
            end
        end

        function errorOnTrailingSeparator(testCase)
            testRootwithSep = testCase.testRoot;
            testRootwithSep = fullfile(testRootwithSep, filesep);
            
            verifyError(testCase,@() AIDIF.constructHiveQueryTable(testRootwithSep),...
                'AIDIF:InvalidPath:TrailingSeparator');

        end

    end

end