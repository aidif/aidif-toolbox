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
rootFolder = "/Users/jan/git/aidif/out";
queryTable = constructHiveQueryTable(rootFolder);

%TODO: Eclude Loop for now
queryTable = queryTable(queryTable.study_name ~= "Loop",:);

%% ingest babelbetes data, by study and subject, for all data types.


%select a random of 6 patients
nPatients = 25;
uniquePatients = unique(queryTable(:,["study_name","patient_id"]));
randomIndexes = randi([1,height(uniquePatients)],nPatients,1);
randomPatients = uniquePatients(randomIndexes,:);


randomPatients
errorLog = {}
%%
for iRandomPatient = 1:height(randomPatients)
    rowMask = ismember(queryTable(:, {'study_name','patient_id'}), randomPatients(iRandomPatient,:));
    rows = queryTable(rowMask,:);
    
    % TODO Any file verification/alignment needed
    if height(rows)~=3
        warning("Patient %s from study %s does not have the expected number of data entries.", ...
                string(randomPatients.patient_id(iRandomPatient)), ...
                string(randomPatients.study_name(iRandomPatient)));
        continue
    end
    if ~all(ismember(rows.data_type,["basal","bolus","cgm"]))
        warning("Patient %s from study %s has missing data.", string(randomPatients.patient_id(iRandomPatient)), string(randomPatients.study_name(iRandomPatient)))
        continue
    end
    
    
    % Resampling
    try
        basalPath = rows(rows.data_type=='basal',"path").path;
        rawBasal = parquetread(basalPath, "OutputType", "timetable");
        basalResampled = AIDIF.interpolateBasal(rawBasal);
    
    catch exception
        
        fprintf('Error processing patient %s from study %s: %s\n', ...
                string(randomPatients.patient_id(iRandomPatient)), ...
                string(randomPatients.study_name(iRandomPatient)), ...
                exception.message);

        
        % Append error details to a structure array
        errorLog(iRandomPatient).study_name = string(randomPatients.study_name(iRandomPatient));
        errorLog(iRandomPatient).patient_id = string(randomPatients.patient_id(iRandomPatient));
        errorLog(iRandomPatient).data_type = 'basal';
        errorLog(iRandomPatient).error_message = exception.message;
        continue
    end
    
    basalResampled
    
    
    % TODO combine cgm, basal, and bolus functions

end
