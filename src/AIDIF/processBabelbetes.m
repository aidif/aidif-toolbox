% PROCESSBABELBETES this script imports the babelbetes subject data streams
%   (cgm, basal, and bolus insulin) and time aligns and interpolates the 
%   data.
%
%   The output of this script returns combined parquet files to the 
%   patient folders collected in the data warehouse. The combined datasets
%   can be used for further analysis.

%   Author: Michael Wheelock
%   Date: 2025-10-08
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

% create the import query table for babelbetes hive schema
rootFolder = "I:\Shared drives\AIDIF internal\03 Model Development\BabelBetes\babelbetes output\2025-11-26 - e2d9611";
queryTable = AIDIF.constructHiveQueryTable(rootFolder);

%% Resample and combine the raw data.
[patientRows,patients] = findgroups(queryTable(:,["study_name" "patient_id"]));

tic
[patients{:,"combinedTT"}, patients{:,"errorLog"}] = splitapply(@(x,y)processPatient(x,y), queryTable.data_type,queryTable.path,patientRows);
toc


function [combinedTT,errorLog] = processPatient(dataType,dataPath)
datasets = cell2table(arrayfun(@(x) parquetread(x,"OutputType","timetable"),dataPath,'UniformOutput',false),'RowNames',dataType,"VariableNames","tt");
errorLog = createLogTemplate();
if height(datasets) ~= 3
    errorLog.isMissingData = 1;
    errorLog = {errorLog};
    combinedTT = {[]};
    return
end

datasets = cell2table(rowfun(@(x) checkAndFormatTables(x,errorLog),datasets,"ExtractCellContents",true,"OutputFormat","cell","NumOutputs",2),"RowNames",dataType,"VariableNames",["tt" "errorLog"]);
errorLog = [datasets.errorLog(:)];

base = AIDIF.readParquetDurationBase(dataPath(contains(dataPath,'bolus')),"delivery_duration");
bolusTT = datasets.tt{datasets.Row("bolus")};
bolusTT.delivery_duration = milliseconds(bolusTT.delivery_duration/base);

try
    cgmTT = AIDIF.interpolateCGM(datasets.tt{datasets.Row("cgm")});
    totalInsulinTT = AIDIF.mergeTotalInsulin(datasets.tt{datasets.Row("basal")},bolusTT,hours(24));
catch ME
    disp(ME.message)
    errorLog(end).errorID = ME.identifier;
    errorLog(end).errorMessage = ME.message;
    errorLog = {errorLog};
    combinedTT = {[]};
    return
end

errorLog(1).isComplete = 1;
errorLog = {errorLog};
combinedTT = {AIDIF.mergeGlucoseAndInsulin(cgmTT,totalInsulinTT)};

end

%helper functions
function [formattedTable,errorLog] = checkAndFormatTables(rawTT,errorLog)

if ~issortedrows(rawTT)
    disp("unsorted")
    errorLog.sorted = 0;
    rawTT = sortrows(rawTT,"datetime","ascend");
end

dups = AIDIF.findDuplicates(rawTT(:,[]));
if any(dups) && width(rawTT) == 1
    disp('duplicates')
    errorLog.hasDuplicates = 1;
    rawTT(dups,:) = [];
end

rawTT = convertvars(rawTT,1,"double");

formattedTable = rawTT;

end

function templateLog = createLogTemplate()
    templateLog = struct("isComplete", 0, ...
        "isMissingData", 0, ...
        "sorted", 1, ...
        "hasDuplicates", 0, ...
        "errorID", "", ...
        "errorMessage", "");
end
