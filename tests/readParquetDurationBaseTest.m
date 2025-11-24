%   Author: Jan Wrede
%   Date: 2025-11-24
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

classdef readParquetDurationBaseTest < matlab.unittest.TestCase
    properties
        tempDir
        parquetFile
    end
    
    methods(TestMethodSetup)
        function setupParquetFile(testCase)
            % Create temporary directory
            testCase.tempDir = tempdir;
            testCase.parquetFile = fullfile(testCase.tempDir, 'python.parquet');
            
            % Python code to create the parquet file
            code = [
                "from datetime import datetime, timedelta" newline ...
                "import pandas as pd" newline ...
                "now = datetime.now()" newline ...
                "df = pd.DataFrame({" newline ...
                "    'datetime': [now + timedelta(hours=i) for i in range(1, 4)]," newline ...
                "    'bolus': [1.2, 2, 3]," newline ...
                "    'delivery_duration': [" newline ...
                "        pd.Timedelta(seconds=1)," newline ...
                "        pd.Timedelta(minutes=2)," newline ...
                "        pd.Timedelta(hours=3)" newline ...
                "    ]" newline ...
                "})" newline ...
                "df.to_parquet('" + testCase.parquetFile + "')" ...
            ];
            pyrun(code);
        end
    end

    
    methods(TestMethodTeardown)
        function teardownParquetFile(testCase)
            % Clean up the parquet file
            if exist(testCase.parquetFile, 'file')
                delete(testCase.parquetFile);
            end
        end
    end
    
    methods(Test)
        function testRestoreDurations(testCase)
            base = AIDIF.readParquetDurationBase(testCase.parquetFile,'delivery_duration');
            tt = parquetread(testCase.parquetFile);
            tt.delivery_duration = milliseconds(tt.delivery_duration/base);
            testCase.verifyEqual(tt.delivery_duration,[seconds(1),minutes(2),hours(3)]')

        end
    end
end
