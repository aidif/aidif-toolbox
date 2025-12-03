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

function results = processBabelbetes(rootFolder, exportRoot, queryTable)

arguments (Input)
    rootFolder char {mustBeTextScalar}
    exportRoot char {mustBeTextScalar} = ""
    queryTable table {mustBeNonempty} = table()
end

    if isempty(queryTable)        
        queryTable = AIDIF.constructHiveQueryTable(rootFolder);
    end
    
    [patientRows, patients] = findgroups(queryTable(:,["study_name" "patient_id"]));
    results = patients;
    tic
    [results.combinedTT, results.errorLog] = splitapply(@(x,y) processPatient(x,y), queryTable.data_type, queryTable.path,patientRows);
    toc

    if strlength(exportRoot) ~= 0
        rowfun(@(x,y,z) exportData(x,y,z,exportRoot),results,"InputVariables",["combinedTT" "study_name" "patient_id"],"SeparateInputs",true,"ExtractCellContents",true);
        disp("data exported to " + exportRoot);
    end

    report(results.errorLog)
end

function [combinedTT,result] = processPatient(dataType,dataPath)
    result = createLogTemplate;
    try
        assert(length(dataType)==3,AIDIF.Constants.ERROR_ID_MISSING_FILE,"Missing files for at least one data type");
    
        datapaths = dictionary(dataType, dataPath);
    
        datasets = dictionary(dataType, arrayfun(@(x) parquetread(x,"OutputType","timetable"),dataPath,UniformOutput=false));
        [datasets(dataType), wasSorted, hadDuplicates] = cellfun(@(x) checkAndFormatTables(x), datasets.values,UniformOutput=false);
        result.sorted = cell2struct(wasSorted, dataType);
        result.duplicated = cell2struct(hadDuplicates, dataType);

        base = AIDIF.FIX_parquetDuration(datapaths("bolus"), "delivery_duration");
        datasets{"bolus"}.delivery_duration = milliseconds(datasets{"bolus"}.delivery_duration/base);
        datasets{"cgm"} = AIDIF.interpolateCGM(datasets{"cgm"});
        datasets{"totalInsulin"} = AIDIF.mergeTotalInsulin(datasets{"basal"}, datasets{"bolus"}, hours(24));

        combinedTT = {AIDIF.mergeGlucoseAndInsulin(datasets{"cgm"},datasets{"totalInsulin"})};
    catch ME
        result.errorID = ME.identifier;
        result.errorMessage = ME.message;
        combinedTT = {[]};
    end
end

function [formattedTable, wasSorted, hadDuplicates] = checkAndFormatTables(rawTT)
    wasSorted = true;
    hadDuplicates = false;

    if ~issortedrows(rawTT)
        wasSorted = false;
        rawTT = sortrows(rawTT,"datetime","ascend");
    end
    
    dups = AIDIF.findDuplicates(rawTT(:,[]));
    if any(dups) && width(rawTT) == 1
        hadDuplicates = true;
        rawTT(dups,:) = [];
    end
    
    formattedTable = convertvars(rawTT,1,"double");
end

function templateLog = createLogTemplate()
    templateLog = struct("sorted", struct, ...
        "duplicated", struct, ...
        "errorID", "", ...
        "errorMessage", "");
end

function report(errorLog)
    hasValidDuplicated = arrayfun(@(x) ~isempty(fields(x.duplicated)), errorLog); 
    validLogs = errorLog(hasValidDuplicated);
    basalDuplicated = sum(arrayfun(@(x) x.duplicated.basal, validLogs))
    cgmDuplicated = sum(arrayfun(@(x) x.duplicated.cgm, validLogs))
    bolusDuplicated = sum(arrayfun(@(x) x.duplicated.bolus, validLogs))
    
    hasValidSorted = arrayfun(@(x) ~isempty(fields(x.sorted)), errorLog); 
    validLogs = errorLog(hasValidSorted);
    basalUnsorted = sum(arrayfun(@(x) ~x.sorted.basal, validLogs))
    cgmUnsorted = sum(arrayfun(@(x) ~x.sorted.cgm, validLogs))
    bolusUnsorted = sum(arrayfun(@(x) ~x.sorted.bolus, validLogs))
    
    
    errorIDs = arrayfun(@(x) string(x.errorID), errorLog);
    errorIDs(strlength(errorIDs) == 0)="success";
    [cnts,grps] = groupcounts(errorIDs)
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

parquetwrite(fullfile(filePath,"babelbetes_combined.parquet"),combinedTT)
done = 1;
end
