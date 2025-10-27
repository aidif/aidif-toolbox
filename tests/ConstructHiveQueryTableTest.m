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

            testCase.partitionData = struct(...
                'StudyName',  {'ABC', 'ABC', 'XYZ'}, ...
                'DataType',   {'D',   'D',   'E'}, ...
                'PatientID',  {'101', '102', '201'}, ...
                'FileName',   {'file1.parquet', 'file2.parquet', 'file3.parquet'}...
                );

            filePaths = {};
            for i = 1:length(testCase.partitionData)
                data = testCase.partitionData(i);

                hivePath = fullfile(...
                    ['study_name=' data.StudyName], ...
                    ['data_type=' data.DataType], ...
                    ['patient_id=' data.PatientID] ...
                    );

                fullDir = fullfile(testCase.testRoot, hivePath);
                mkdir(fullDir);
                fullFile = fullfile(fullDir, data.FileName);

                % Create an empty file .parquet file
                fid = fopen(fullFile, 'w');
                if fid ~= -1
                    fclose(fid);
                    filePaths{end+1} = fullFile;
                else
                    warning('Could not create test file: %s', fullFile);
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