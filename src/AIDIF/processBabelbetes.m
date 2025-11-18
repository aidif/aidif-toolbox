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

import AIDIF.*

%% create the import query table for babelbetes hive schema
%assign root folder for babelbetes data partition in rootFolder variable
rootFolder = "I:/Shared drives/AIDIF internal/03 Model Development/BabelBetes/babelbetes output/2025-09-23";
queryTable = constructHiveQueryTable(rootFolder);

%% ingest babelbetes data, by study and subject, for all data types.
% create subset for example processing
uniquePatient = unique(queryTable(:,["study_name" "patient_id"]),"rows","stable");

tic
completeCounter = 0; % count patients that finish
breakFlag = 0; % flag to abort patient processing if error
for iPatient = 1:height(uniquePatient)

    patientFiles = queryTable(queryTable.study_name == uniquePatient.study_name(iPatient) &...
        queryTable.patient_id == uniquePatient.patient_id(iPatient),:);

    if height(patientFiles) == 3 && all(ismember(patientFiles.data_type,["cgm","basal","bolus"]))

        for iFile = 1:height(patientFiles)

            currentDataType = patientFiles.data_type(iFile);

            %Apply general corrections
            rawData = parquetread(patientFiles.path(iFile),"OutputType","timetable");
            rawData = sortrows(rawData,'datetime','ascend');
            dups = findDuplicates(rawData(:,[]));
            rawData(dups,:) = [];

            switch currentDataType
                case "cgm"
                    % cgm corrections
                    rawData.cgm = double(rawData.cgm);
                    try
                        cgmTT = interpolateCGM(rawData);
                    catch ME
                        if strcmp(ME.identifier,TestHelpers.ERROR_ID_INSUFFICIENT_DATA)
                            ME.message
                            warning("Patient %s from study %s failed. Unable to process %s data.", patientFiles.patient_id(iFile),...
                                patientFiles.study_name(iFile),currentDataType)
                            breakFlag = 1;
                            break
                        end
                    end

                case "basal"
                    % basal corrections
                    rawData(isnan(rawData.basal_rate),:) = [];
                    try
                        basalTT = interpolateBasal(rawData);
                    catch ME
                        if strcmp(ME.identifier,TestHelpers.ERROR_ID_INSUFFICIENT_DATA)
                            ME.message
                            warning("Patient %s from study %s failed. Unable to process %s data.", patientFiles.patient_id(iFile),...
                                patientFiles.study_name(iFile),currentDataType)
                            breakFlag = 1;
                            break
                        end
                    end

                case "bolus"
                    % bolus corrections
                    rawData(rawData.bolus == 0,:) = [];
                    rawData.delivery_duration = seconds(rawData.delivery_duration);
                    try
                        bolusTT = interpolateBolus(rawData);
                    catch ME
                        if strcmp(ME.identifier,TestHelpers.ERROR_ID_OVERLAPPING_DELIVERIES)
                            ME.message
                            warning("Patient %s from study %s failed. Unable to process %s data.", patientFiles.patient_id(iFile),...
                                patientFiles.study_name(iFile),currentDataType)
                            breakFlag = 1;
                            break
                        else
                            ME.message
                            warning("Patient %s from study %s failed. %s data had unexpected error.", patientFiles.patient_id(iFile),...
                                patientFiles.study_name(iFile),currentDataType)
                            breakFlag = 1;
                            break
                        end
                    end

                otherwise
                    disp(currentDataType + " file not processed.")
            end
        end
    else
        warning("Patient %s from study %s has missing data.", patientFiles.patient_id(1), patientFiles.study_name(1))
        continue
    end

    if  breakFlag == 1
        breakFlag = 0;
        clear cgmTT basalTT bolusTT
        continue
    end

    completeCounter = completeCounter + 1;

    combinedTT = mergeGlucoseAndInsulin(cgmTT,basalTT,bolusTT);
    clear cgmTT basalTT bolusTT

end
toc
