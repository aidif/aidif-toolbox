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

import AIDIF.*

%% create the import query table for babelbetes hive schema
%assign root folder for babelbetes data partition in rootFolder variable
rootFolder = "I:/Shared drives/AIDIF internal/03 Model Development/BabelBetes/babelbetes output/2025-09-23";
queryTable = constructHiveQueryTable(rootFolder);

%% Resample and combine the raw data.

patientRows = findgroups(queryTable(:,["study_name" "patient_id"]));
tic
splitapply(@processPatient, queryTable.data_type,queryTable.path,patientRows);
toc

%Split apply function
function processPatient(dataType,path)
datasets = cell2table(arrayfun(@(x) parquetread(x,"OutputType","timetable"),path,'UniformOutput',false),"VariableNames","tt");
if height(datasets) ~= 3
    log = "Patient is missing cgm, bolus, or basal data."
    combinedTT = [];
    return
end

datasets = cell2table(rowfun(@checkAndFormatTables,datasets,"ExtractCellContents",true,"OutputFormat","cell","NumOutputs",2),"RowNames",dataType,"VariableNames",["tt" "errorLog"]);
if ~isempty([datasets.errorLog{:}])
    return
end

for i = 1:height(datasets)
    try
        switch dataType(i)
            case "cgm"
                cgmTT = AIDIF.interpolateCGM(datasets.tt{i});
            case "basal"
                basalTT = AIDIF.interpolateBasal(datasets.tt{i});
            case "bolus"
                bolusTT = AIDIF.interpolateBolus(datasets.tt{i});
        end
    catch ME
        log = ME.message
        combinedTT = [];
        return
    end
end
combinedTT = AIDIF.mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT);
end

%helper functions
function [formattedTable,log] = checkAndFormatTables(rawTT)

rawTT = sortrows(rawTT,"datetime","ascend");
dups = AIDIF.findDuplicates(rawTT(:,[]));
rawTT(dups,:) = [];
rawTT = convertvars(rawTT,1,"double");

if any(ismember(rawTT.Properties.VariableNames,'delivery_duration'))
    rawTT.delivery_duration = seconds(rawTT.delivery_duration);
end
formattedTable = rawTT;
log = [];

end
