function [combinedTable] = importByDataType(filePaths,dataType)
%IMPORTBABELBETES import babelbetes parquet files into combined tables of
%one datatype(cgm, basal, or bolus)
%   filePaths - array of filepaths to babelbetes parquet files to read
%   datatype - datatype specified for the continuous table ('cgm', 'bolus',
%      'basal') 
%   combinedTable - continuous table of parquet file data, with unique
%      identifier

arguments (Input)
    filePaths
    dataType
end

arguments (Output)
    combinedTable
end


relevantFiles = filePaths(filePaths.data_type == dataType,:);

f = waitbar(0,['loading ' char(dataType) ' data.']);
for i = 1:height(relevantFiles)

    tempTable = parquetread(relevantFiles.filePaths(i));
    tempTable{:,"unique_id"} = relevantFiles.unique_id(i);
    
    if i == 1
        combinedTable = tempTable;
    else
        combinedTable = [combinedTable; tempTable];
    end
    waitbar(i/height(relevantFiles),f)
end
close(f)
end