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
exportRoot = "I:/Shared drives/AIDIF internal/03 Model Development/BabelBetes/MATLAB/" +string(datetime("today","Format","uuuu-MM-dd"));
queryTable = AIDIF.constructHiveQueryTable(rootFolder);

%% Resample and combine the raw data.
[patientRows,patients] = findgroups(queryTable(:,["study_name" "patient_id"]));

tic
[patients{:,"combinedTT"}, patients{:,"errorLog"}] = splitapply(@(x,y)processPatient(x,y), queryTable.data_type,queryTable.path,patientRows);
rowfun(@(x,y,z) exportData(x,y,z,exportRoot),patients,"InputVariables",["combinedTT" "study_name" "patient_id"],"SeparateInputs",true,"ExtractCellContents",true)
toc

function [combinedTT,errorLog] = processPatient(dataType,dataPath)
%processPatients compiles patient data into final timetable output.
%   Inputs:
%   dataType - string array of the datatypes, relating to the file contents
%       of dataPath
%   dataPath - array of file paths for parquet files to be processed.
%
%   Outputs:
%   combinedTT - cumulative timetable for one patient.
%       'egv' - estimated glucose values (mg/dL)
%       'totalInsulin' - combined insulin delivery from bolus and basal
%       datasets.
%   errorLog - table of logical and string variables indicating caught and
%   hotfixed errors.
%
%   see also checkAndFormatTables, createLogTemplate
errorLog = createLogTemplate();
if height(dataPath) ~= 3
    errorLog.isMissingData = 1;
    errorLog = {errorLog};
    combinedTT = {[]};
    return
end
datasets = cell2table(arrayfun(@(x) parquetread(x,"OutputType","timetable"),dataPath,'UniformOutput',false),'RowNames',dataType,"VariableNames","tt");

datasets = cell2table(rowfun(@(x) checkAndFormatTables(x,errorLog),datasets,"ExtractCellContents",true,"OutputFormat","cell","NumOutputs",2),"RowNames",dataType,"VariableNames",["tt" "errorLog"]);
errorLog = [datasets.errorLog(:)];

%bolus duration schema correction
base = AIDIF.readParquetDurationBase(dataPath(contains(dataPath,'bolus')),"delivery_duration");
bolusTT = datasets.tt{datasets.Row("bolus")};
bolusTT.delivery_duration = milliseconds(bolusTT.delivery_duration/base);

try
    cgmTT = AIDIF.interpolateCGM(datasets.tt{datasets.Row("cgm")});
    totalInsulinTT = AIDIF.mergeTotalInsulin(datasets.tt{datasets.Row("basal")},bolusTT,hours(24));
catch ME
    disp(ME.message)
    % errorLog{end,["errorID" "errorMessage"]} = [ME.identifierer ME.message];
    errorLog = {errorLog};
    combinedTT = {[]};
    return
end

errorLog(1).isComplete = 1;
errorLog = {errorLog};
combinedTT = {AIDIF.mergeGlucoseAndInsulin(cgmTT,totalInsulinTT)};
end

function done = exportData(combinedTT,studyName,patientID,exportRoot)
%exportData exports combined datasets as parquet files in a hive schema
%folder structure.
if isempty(combinedTT)
    done = 0;
    return
end
filePath = fullfile(exportRoot,"study_name=" + studyName,"data_type=combined",...
    "patient_id="+patientID);
mkdir(filePath)
parquetwrite(filePath+"\babelbetes_combined.parquet",combinedTT)
done = 1;
end

%% helper functions

function [formattedTable,errorLog] = checkAndFormatTables(rawTT,errorLog)
%checkAndFormatTables check for, log and correct minor discrepencies of timetables.
%   This function sorts, removes duplicates of egv and basal, and converts
%   table variable types to allow data to pass that would otherwise fail.
if ~issortedrows(rawTT)
    disp("unsorted")
    errorLog.sorted = 0;
    rawTT = sortrows(rawTT,"datetime","ascend");
end

dups = AIDIF.findDuplicates(rawTT(:,[]));
% not checking for duplicates in bolus here
if any(dups) && width(rawTT) == 1
    disp('duplicates')
    errorLog.hasDuplicates = 1;
    rawTT(dups,:) = [];
end

rawTT = convertvars(rawTT,1,"double");
formattedTable = rawTT;
end

function templateLog = createLogTemplate()
%createLogTemplate creates error log template for processBabelbetes.
    templateLog = struct("isComplete", 0, ...
        "isMissingData", 0, ...
        "sorted", 1, ...
        "hasDuplicates", 0, ...
        "errorID", "", ...
        "errorMessage", "");
end

