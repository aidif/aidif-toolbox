function [queryTable] = constructQueryTable(rootFolder)
%CONSTRUCTQUERYTABLE creates a table to use for querying datasets with hive
%   schema formatting.
%
%   QUERYTABLE = CONSTRUCTQUERYTABLE("babelbetes/path")
%
%   INPUTS:
%   rootFolder: the root path of the dataset under hive schema.
%
%   OUTPUTS:
%   queryTable: table which maps the parquet file path to the hive schema levels 
%   patient_id, study_name and data_type.
%
%   Example:
%
%   See also: parquetdatastore
%
%   Author: Michael Wheeloc
%   Date: 2025-10-08
%   Copyright: AIDIF


arguments (Input)
    rootFolder
end

arguments (Output)
    queryTable
end

%get all parquet file paths
files = dir(fullfile(rootFolder, '**', '*.parquet'));
fullPaths = fullfile({files.folder}, {files.name})';

%Add columns for study, patient and data type
tokens = regexp(fullPaths, 'study_name=([^/]+)/data_type=([^/]+)/patient_id=([^/]+)/[^/]+\.parquet$', ...
    'tokens', 'once');
tokens = string(vertcat(tokens{:}));
queryTable = table(tokens(:,1), tokens(:,2), tokens(:,3), fullPaths, ...
    'VariableNames', {'study_name', 'data_type', 'patient_id', 'full_path'});
end