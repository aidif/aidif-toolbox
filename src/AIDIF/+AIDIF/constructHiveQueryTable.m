function [queryTable] = constructHiveQueryTable(rootFolder)
%CONSTRUCTQUERYTABLE creates a table for querying datasets with hive-style
%   partitioning.
%
%   INPUTS:
%   rootFolder: the root path of the dataset under hive schema.
%
%   OUTPUTS:
%   queryTable: table which contains the unique path to all data files
%      in the subfolders of rootFolder, with variables columns for each
%      subfolder level to query for.
%   datastoreOutput: the datastore object used for collecting all
%      subfolder paths.
%
%   Example:
%
%   See also: parquetdatastore
%
%   Author: Michael Wheelock
%   Date: 2025-10-08
%   Copyright: AIDIF


arguments (Input)
    rootFolder char {mustBeFolder}
end

arguments (Output)
    queryTable table
end

queryTable = struct2table(dir(fullfile(rootFolder,"**/*.parquet")));
queryTable = removevars(queryTable,["bytes" "date" "datenum" "isdir"]);
queryTable(:,"path") = fullfile(queryTable.folder,queryTable.name);

% deconstruct 'folder' variable into searchable hive schema components
queryTable.folder = strrep(queryTable.folder,fullfile(rootFolder),'');
queryTable.folder = split(queryTable.folder,filesep);
hiveInfo = split(queryTable.folder,"=");

%insert hive schema queries into table
queryTable.folder = hiveInfo(:,:,2);
queryTable = splitvars(queryTable,"folder","NewVariableNames",hiveInfo(1,:,1));

end