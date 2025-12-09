function results = processBabelbetes(rootFolder, NameValueArgs)
% PROCESSBABELBETES imports, resamples, and synchronizes babelbetes subject data streams into a combined timetable.
%
%   Syntax:
%   results = processBabelbetes(rootFolder) - process babelbetes patient
%       data found in rootfolder. Results contains the combined timetables
%       and error log for each patient.
%   results = processBabelbetes(rootFolder, exportPath) - exports the
%       combined patient datatables to the provided path, exportPath.
%   results = processBabelbetes(rootFolder, queryTable) - pass in a table
%       specifying which studies, patients, and data types of rootfolder to
%       process. 
%   results = processBabelbetes(rootFolder, exportPath, queryTable) -
%       process the specified patient files specified in queryTable and
%       export to the root path, exportPath.
%
%   Inputs:
%   rootFolder - string scalar of the root path for the babelbetes hive
%       schema
%
%   (name-value pair arguments)
%   exportPath = string scalar of the root path for the combined
%       timetables to be exported to. Combined tables are saved as paquet files
%       in a hive file schema.
%   queryTable - queryTable of the babelbetes rootFolder schema. Pass
%   this argument in to process a subset of the rootFolder data.
%
%   Outputs:
%   results: table containing various processing variables.
%       'study_name' - string array of study names.
%       'patient_id' - string array of patient IDs.
%       'combinedTT' - cell array of tables, containing the time aligned,
%           merged glucose and insulin for each processed patient.
%           `egv` - the estimated glucose values (mg/dL) from the patients'
%           cgm devices.
%           `totalInsulin` - the total insulin delivery (U) for the combined basal rates and bolus deliveries
%       'errorLog' - cell array of structs, containing a log of errors and
%           warnings for each processed patient.
%
%   Additional Information:
%   combinedTT design:
%       - The combinedTT timetable represents the intersect of all data
%       streams.
%       - insulin delivery rates are valid up until a 24 hour gap with no
%       original insulin data is received. insulin gaps larger than 24
%       hours are set to NaN.
%       - EGV gaps are valid up to a 30 minute gap with no new egv signal.
%       Gaps in egv >= 30 minutes are set to NaN.
%
%   errorLog information:
%       The following errors in the input data structure will prevent the
%   combinedTT from processing:
%       - the patient is missing a data file (cgm, basal, or bolus)
%       - the patient cgm or basal raw data is <2 two rows of data.
%       - the patient bolus data contains overlapping extended boluses.
%       - the patient datasets contain duplicate rows.
%       - the patient datasets contain unsorted rows.
%
%       The following issues with the datasets are corrected in processing
%       and not reported:
%       - table data types are converted to double
%       - bolus parquet unit values are interpreted and applied to the
%           duration array for the delivery_duration variable.

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
    rootFolder char {mustBeTextScalar}

    NameValueArgs.exportPath char {mustBeTextScalar} = ""
    NameValueArgs.queryTable table = table()
end

queryTable = NameValueArgs.queryTable;
if isempty(queryTable)
    queryTable = AIDIF.constructHiveQueryTable(rootFolder);
end

[patientRows, patients] = findgroups(queryTable(:,["study_name" "patient_id"]));
results = patients;
tic
[results.combinedTT, results.errorLog] = splitapply(@(x,y) processPatient(x,y), queryTable.data_type, queryTable.path,patientRows);
toc

if strlength(NameValueArgs.exportPath) ~= 0
    rowfun(@(x,y,z) exportData(x,y,z,NameValueArgs.exportPath),results,"InputVariables",["combinedTT" "study_name" "patient_id"],"SeparateInputs",true,"ExtractCellContents",true);
    disp("data exported to " + NameValueArgs.exportPath);
end

report(results.errorLog)
end

function [combinedTT,result] = processPatient(dataType,dataPath)
    result = struct("errorID", "", "errorMessage", "");
try
    assert(length(dataType)==3,AIDIF.Constants.ERROR_ID_MISSING_FILE,"Missing files for at least one data type");

    datapaths = dictionary(dataType, dataPath);

    datasets = dictionary(dataType, arrayfun(@(x) parquetread(x,"OutputType","timetable"),dataPath,UniformOutput=false));
    datasets(dataType) = cellfun(@(x) convertvars(x,1,"double"), datasets.values,UniformOutput=false);

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

function report(errorLog)
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
