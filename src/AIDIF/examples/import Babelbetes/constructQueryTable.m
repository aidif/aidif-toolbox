function [queryTable,datastoreOutput] = constructQueryTable(rootFolder)
%constructQueryTable creates a table to use for querying datasets with hive
%   schema formatting.
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
%   Author: Michael Wheeloc
%   Date: 2025-10-08
%   Copyright: AIDIF


arguments (Input)
    rootFolder
end

arguments (Output)
    queryTable
    datastoreOutput
end

datastoreOutput = parquetDatastore(rootFolder,"IncludeSubfolders",true,"OutputType","timetable","PartitionMethod","file","ReadSize","file");

queryTable = cell2table(datastoreOutput.Files);
queryTable.Var1 = string(queryTable.Var1);
queryTable.Var1 = rowfun(@(x) replace(x,'\','/'),queryTable,"InputVariables","Var1","OutputFormat","uniform");
queryTable(:,2) = queryTable(:,1);
queryTable = renamevars(queryTable,"Var2","filePaths");

queryTable.Var1 = rowfun(@(x) replace(x,rootFolder,''),queryTable,"InputVariables","Var1","OutputFormat","uniform");
queryTable.Var1 = split(queryTable.Var1,'/');

queryLevels = queryTable.Var1(1,:);
queryLevels = strtok(queryLevels,'=');
queryLevels{1,end} = 'fileName';

queryTable = splitvars(queryTable,"Var1","NewVariableNames",queryLevels)
queryTable(:,queryLevels(1:end-1)) = varfun(@(x) extractAfter(x,'='),queryTable,"InputVariables",queryLevels(1:end-1))

queryTable.patient_id = str2double(queryTable.patient_id)


end