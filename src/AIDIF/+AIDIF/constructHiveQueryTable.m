function queryTable = constructHiveQueryTable(rootFolder)
% CONSTRUCTHIVEQUERYTABLE creates a table for querying datasets with
%   hive-style partitioning.
%
%   queryTable = constructHiveQueryTable(rootfolder) returs a table 
%       containing the full paths of a hive-style partitioned datastore, 
%       as well as variables for each partition key and value.
%
%   INPUTS:
%   rootFolder: the root path of the dataset under hive schema.
%
%   OUTPUTS:
%   queryTable: table which contains the unique path to all data files
%      in the subfolders of rootFolder, with variables columns for each
%      partition key and value to query for.

%   Author: Michael Wheelock
%   Date: 2025-10-08
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved


arguments (Input)
    rootFolder char {mustBeTextScalar, mustBeFolder, ...
                     mustNotHaveTrailingSeparator}
end

arguments (Output)
    queryTable table
end

queryTable = struct2table(dir(fullfile(rootFolder,"**/*.parquet")));
queryTable = removevars(queryTable,["bytes" "date" "datenum" "isdir"]);
queryTable(:,"path") = fullfile(queryTable.folder,queryTable.name);

% deconstruct 'folder' variable into searchable hive schema components
queryTable.folder = strrep(queryTable.folder, [fullfile(rootFolder) filesep],'');
queryTable.folder = split(queryTable.folder,filesep);
hiveInfo = split(queryTable.folder,"=");

%insert hive schema queries into table
queryTable.folder = hiveInfo(:,:,2);
queryTable = splitvars(queryTable,"folder", "NewVariableNames",hiveInfo(1,:,1));
queryTable = removevars(queryTable,"name");
queryTable = convertvars(queryTable,[1:width(queryTable)],'string');

end
    
function mustNotHaveTrailingSeparator(path)
    path = char(path);
    if ismember(path(end),["/" "\"])
        error([path ' must not have a trailing separator, "/" or "\".'])
    end

end