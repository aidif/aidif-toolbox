%[text] ## **Catching Babelbetes Errors**
%[text] ### **AIDIF**
%[text] #### Author: Jan Wrede
%[text] #### Date created: 2025-11-13
%[text] <u>Abstract</u>: The purpose of this research script is to identify the type and counts of errors caught in MATLAB which stem from the initial processing of the JAEB dataset from babelbetes. The objective is to identify the errors contained in the basal, bolus, and egv data streams in order to correct them with babelbetes. This script will be updated when the results indicate no more data formatting errors are found.
%%
%[text] <u>Process:</u> The babelbetes output will be imported and processed in MATLAB similarly to the approach used in processBabeletes. The distinction is that no efforts are made to sanitize the incoming data, allowing error mesages to be caught in try...catch logic.
%% create the import query table for babelbetes hive schema
% assign root folder for babelbetes data partition in rootFolder variable
rootFolder = "I:\Shared drives\AIDIF internal\03 Model Development\BabelBetes\babelbetes output\2025-09-23";
queryTable = AIDIF.constructHiveQueryTable(rootFolder);
fprintf("There are %d rows",height(queryTable)) %[output:07c6a894]

% TODO: Eclude Loop for now
% queryTable = queryTable(queryTable.study_name ~= "Loop",:);
%%
%% ingest babelbetes data, by study and subject, for all data types.

% select a random of 6 patients

patients = unique(queryTable(:,["study_name","patient_id"]));
fprintf("There are %d unique patients",height(patients)); %[output:4e7dfa61]
nPatients = 200;
randomIndexes = randi([1,height(patients)],nPatients,1);
patients = patients(randomIndexes,:);
%%
DATA_TYPES = ["basal","bolus","cgm"];

logs = cell(height(patients),3);
for iPatient = 1:height(patients) %[output:group:65c08966]
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
                        ttResampled = AIDIF.interpolateCGM(ttRaw); %[output:6d09cccf] %[output:604ac30e] %[output:9359764f] %[output:7e9d8fc0] %[output:329c92c1] %[output:9b20a1ce] %[output:2fe2503c] %[output:7b8315ec] %[output:70586996] %[output:0fd07603] %[output:130d0114] %[output:5e9cb103] %[output:72d84889] %[output:2997b968] %[output:357709da] %[output:6cade48d] %[output:9307a89d] %[output:89b0017a] %[output:135712cb] %[output:008f6014] %[output:2cd6e810] %[output:10c1a158] %[output:692ecc47] %[output:70123fa4] %[output:0f4ce323] %[output:623e673a] %[output:65646fac] %[output:891774cb] %[output:395bd914] %[output:5d5ec96c] %[output:1908efee] %[output:83c8d7c8] %[output:350fff1b] %[output:72b497eb] %[output:715b367c] %[output:75059831] %[output:58beb4ce] %[output:340cd392] %[output:88745e96] %[output:6592fa71] %[output:1dc22818] %[output:9f4484b1] %[output:57471569] %[output:45b6d574] %[output:6d793d7c] %[output:6cd06745] %[output:87847351] %[output:5284ed3f] %[output:4b87ab38] %[output:1f8668c1] %[output:3e6212ce] %[output:50ea85d3] %[output:2a1d71f8]
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
end %[output:group:65c08966]

logTable = struct2table([logs{:}]);
successCounts = groupsummary(logTable, ["study_name", "data_type", "result"]);
successRates = groupsummary(logTable, ["study_name","data_type"], @(r) mean(strcmp(r, 'success'))*100, "result");

resultCounts = groupsummary(logTable, ["study_name", "data_type", "result"]);
sortrows(resultCounts,["study_name","data_type"]) %[output:5881da0a]



%errorLogTable = logTable(logTable.result ~= 'success',:);
%errorSummary = groupsummary(errorLogTable, ["study_name", "data_type", "result"]);
%errorSummary = sortrows(errorSummary,'GroupCount','descend');


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
%[output:07c6a894]
%   data: {"dataType":"text","outputData":{"text":"There are 7535 rows","truncated":false}}
%---
%[output:4e7dfa61]
%   data: {"dataType":"text","outputData":{"text":"There are 2566 unique patients","truncated":false}}
%---
%[output:6d09cccf]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:604ac30e]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:9359764f]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:7e9d8fc0]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:329c92c1]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:9b20a1ce]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:2fe2503c]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:7b8315ec]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:70586996]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:0fd07603]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:130d0114]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:5e9cb103]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:72d84889]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:2997b968]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:357709da]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:6cade48d]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:9307a89d]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:89b0017a]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:135712cb]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:008f6014]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:2cd6e810]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:10c1a158]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:692ecc47]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:70123fa4]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:0f4ce323]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:623e673a]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:65646fac]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:891774cb]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:395bd914]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:5d5ec96c]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:1908efee]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:83c8d7c8]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:350fff1b]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:72b497eb]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:715b367c]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:75059831]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:58beb4ce]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:340cd392]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:88745e96]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:6592fa71]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:1dc22818]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:9f4484b1]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:57471569]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:45b6d574]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:6d793d7c]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:6cd06745]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:87847351]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:5284ed3f]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:4b87ab38]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:1f8668c1]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:3e6212ce]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:50ea85d3]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values greater than 400 mg\/dL."}}
%---
%[output:2a1d71f8]
%   data: {"dataType":"warning","outputData":{"text":"Warning: 'cgm' contains values less than 40 mg\/dL."}}
%---
%[output:5881da0a]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study_name","data_type","result","GroupCount"],"columns":4,"dataTypes":["string","string","string","double"],"header":"41×4 table","name":"ans","rows":41,"type":"table","value":[["\"DCLP3\"","\"basal\"","\"success\"","7"],["\"DCLP3\"","\"bolus\"","\"Invalid argument at position 1. ''bolus'' column must contain finite, positive values.\"","6"],["\"DCLP3\"","\"bolus\"","\"Invalid argument at position 1. 'duration' column must contain positive durations.\"","1"],["\"DCLP3\"","\"cgm\"","\"Input timetables must contain unique row times when synchronizing using 'linear'.\"","1"],["\"DCLP3\"","\"cgm\"","\"Interpolation failed for the variable 'cgm' when synchronizing using 'linear':\n\nSample values must be double, single, duration, or datetime.\"","6"],["\"DCLP5\"","\"basal\"","\"Invalid argument at position 1. ''tt''must be sorted ascending by time.\"","8"],["\"DCLP5\"","\"bolus\"","\"Invalid argument at position 1. ''bolus'' column must contain finite, positive values.\"","6"],["\"DCLP5\"","\"bolus\"","\"Invalid argument at position 1. 'duration' column must contain positive durations.\"","2"],["\"DCLP5\"","\"cgm\"","\"Invalid argument at position 1. ''tt' 'must be sorted ascending by time.\"","8"],["\"Flair\"","\"basal\"","\"success\"","10"],["\"Flair\"","\"bolus\"","\"Invalid argument at position 1. 'duration' column must contain positive durations.\"","10"],["\"Flair\"","\"cgm\"","\"Invalid argument at position 1. ''tt' 'must be sorted ascending by time.\"","10"],["\"IOBP2\"","\"basal\"","\"Invalid argument at position 1. ''tt''must be sorted ascending by time.\"","7"],["\"IOBP2\"","\"basal\"","\"success\"","26"]]}}
%---
