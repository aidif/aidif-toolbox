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
logs = cell(height(patients),1);
for iPatient = 1:height(patients)
    rowMask = ismember(queryTable(:, {'study_name','patient_id'}), patients(iPatient,:));
    rows = queryTable(rowMask,:);
    
    if ~all(ismember(rows.data_type,["basal","bolus","cgm"]))
        warning("Patient %s from study %s has missing data.", string(patients.patient_id(iPatient)), string(patients.study_name(iPatient)))
        continue
    end
    
    % Resampling
    try
        basalPath = rows(rows.data_type=='basal',"path").path;
        rawBasal = parquetread(basalPath, "OutputType", "timetable");
        basalResampled = AIDIF.interpolateBasal(rawBasal);
        result = "success";
    catch exception
        
        fprintf('Error processing patient %s from study %s: %s\n', ...
                string(patients.patient_id(iPatient)), ...
                string(patients.study_name(iPatient)), ...
                exception.message);
        result = exception.message;
    end
   
     s=struct("study_name", string(patients.study_name(iPatient)),...
        "patient_id", string(patients.patient_id(iPatient)),...
        "data_type", "basal",...
        "result", result);
     logs{iPatient} = s;
end

logTable = struct2table([logs{:}]);
groupsummary(logTable, ["study_name", "result"])

errorLogTable = logTable(logTable.result ~= 'success',:);
errorSummary = groupsummary(errorLogTable, ["study_name", "result"]);
errorSummary = sortrows(errorSummary,'GroupCount','descend');
