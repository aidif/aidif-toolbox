function base = FIX_parquetDuration(parquetFilePath, durationColumnName)
% FIX_PARQUETDURATION Reads the duration columns unit and provides the base factor to convert to milliseconds
%   base = readParquetDurationUnit(parquetFilePath, durationColumnName)
%
%   This function uses Python's pyarrow library to read the arrow schema
%   from a parquet file and extract the duration unit for a specified
%   column. It then returns the base value to convert the duration value to
%   milliseconds. This is necessary because MATLAB's parquetread function doesn't properly
%   handle duration types and treats them as int64 regardless of wether
%   these represent microseconds or nanoseconds.
%
%   Inputs:
%     parquetFilePath - string or char array, path to the parquet file
%     durationColumnName - string or char array, name of the duration column
%
%   Outputs:
%     base - double time unit conversion factor to convert duration values to milliseconds: 
%     duration[ms] = duration/conversionFactor
%
%   Requirements:
%     - Python virtual environment under `venv` with pyarrow installed
%

%   Author: Jan Wrede
%   Date: 2025-11-24
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

    arguments
        parquetFilePath (1,1) string
        durationColumnName (1,1) string
    end
    
    if ~isfile(parquetFilePath)
        error(AIDIF.Constants.ERROR_ID_MISSING_FILE, 'Parquet file %s not found', parquetFilePath);
    end
    code = ["import pyarrow.parquet as pq" newline ...
        "import regex" newline ...
        "p = regex.compile(r'\[(..)\]');" newline ...
        "schema = pq.ParquetFile(path).schema_arrow;"];
    arrowSchema = pyrun(code,'schema',path=parquetFilePath);
    field = arrowSchema.field(durationColumnName);
    unit = string(field.type.unit);
    switch unit
        case "ns"
            base = 1e6;
        case "us"
            base = 1e3;
        otherwise
            error(AIDIF.Constants.ERROR_ID_INVALID_DATA_TYPE, "Unit %s not expected", unit);
    end

end
