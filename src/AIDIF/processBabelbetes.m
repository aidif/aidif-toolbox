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
%   Copyright (c) year, AIDIF
%   All rights reserved

import AIDIF.constructHiveQueryTable

%% create the import query table for babelbetes hive schema
%assign root folder for babelbetes data partition in rootFolder variable
rootFolder = "your/babelbetes/rootpath/here";
queryTable = constructHiveQueryTable(rootFolder);

%% ingest babelbetes data, by study and subject, for all data types.
% create subset for example processing
subset = queryTable(ismember(queryTable.study_name,"DCLP3") & ...
                    ismember(queryTable.patient_id,string(1:10)),:);
[~,uniquePatient,occurrences] = unique(subset(:,["study_name" "patient_id"]),...
                                "rows","stable");

for iPatient = 1:numel(uniquePatient)

    relevantPaths = subset(occurrences == uniquePatient(iPatient),:)
    %TODO Any file verification/alignment needed
    for iFile = 1:height(relevantPaths)

        currentDataType = relevantPaths.data_type(iFile);
        rawData = parquetread(relevantPaths.path(iFile),"OutputType","timetable");

        switch currentDataType
            case "cgm"
                disp("case 1: " + currentDataType + ...
                    " data resampled for patient " + string(iPatient))
            case "basal"
                disp("case 2: " + currentDataType + ...
                    " data resampled for patient " + string(iPatient))
            case "bolus"
                disp("case 3: " + currentDataType + ...
                    " data resampled for patient " + string(iPatient))
            otherwise
                disp(currentDataType + " file not processed.")
        end
    end

    % TODO combine cgm, basal, and bolus functions

end