% PROCESSBABELBETES this script imports the babelbetes subject data streams
%   (cgm, basal, and bolus insulin) and time aligns and interpolates the 
%   data to the requirements specified for RST#1
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

import AIDIF.constructHiveQueryTable

%% create the import query table for babelbetes hive schema
%assign root folder for babelbetes data partition in rootFolder variable
rootFolder = "/Users/jan/git/nudgebg/babelbetes/data/out";
queryTable = constructHiveQueryTable(rootFolder);
fprintf("There are %d rows",height(queryTable))

%TODO: Eclude Loop for now
%queryTable = queryTable(queryTable.study_name ~= "Loop",:);

%% ingest babelbetes data, by study and subject, for all data types.


%select a random of 6 patients

patients = unique(queryTable(:,["study_name","patient_id"]));
fprintf("There are %d unique patients",height(patients));
nPatients = 200;
%randomIndexes = randi([1,height(patients)],nPatients,1);
%patients = patients(randomIndexes,:);

%%
DATA_TYPES = ["basal","bolus","cgm"];

logs = cell(height(patients),3);
for iPatient = 1:height(patients)
    rowMask = ismember(queryTable(:, {'study_name','patient_id'}), patients(iPatient,:));
    rows = queryTable(rowMask,:);
    
    patient = string(patients.patient_id(iPatient));
    study = string(patients.study_name(iPatient));

    if ~all(ismember(rows.data_type,["basal","bolus","cgm"]))
        warning("Patient %s from study %s has missing data.", patient, study)
    end
    
    for iType = 1:1:3
        dataType = DATA_TYPES(iType);
        try
            if any(ismember(rows.data_type,dataType))
                path = rows(rows.data_type==dataType,"path").path;
                ttRaw = parquetread(path, "OutputType", "timetable");
                switch dataType
                    case "basal"
                        ttResampled = AIDIF.interpolateBasal(ttRaw);
                    case "bolus"
                        ttResampled = AIDIF.interpolateBolus(ttRaw);
                    case "cgm"
                        ttResampled = AIDIF.interpolateCGM(ttRaw);
                end
                result = "success";
            else
                error("No %s file found",dataType);
            end
        catch exception
            %fprintf('Error %s | %s | %s : %s\n', study, patient, dataType,exception.message);
            result = exception.message;
        end

         s=struct("study_name", study, "patient_id", patient, "data_type", dataType, "result", result);
         logs{iPatient,iType} = s;
    end
end

logTable = struct2table([logs{:}]);
successCounts = groupsummary(logTable, ["study_name", "data_type", "result"]);
successRates = groupsummary(logTable, ["study_name","data_type"], @(r) mean(strcmp(r, 'success'))*100, "result");

resultCounts = groupsummary(logTable, ["study_name", "data_type", "result"]);
sortrows(resultCounts,["study_name","data_type"])



%errorLogTable = logTable(logTable.result ~= 'success',:);
%errorSummary = groupsummary(errorLogTable, ["study_name", "data_type", "result"]);
%errorSummary = sortrows(errorSummary,'GroupCount','descend');
