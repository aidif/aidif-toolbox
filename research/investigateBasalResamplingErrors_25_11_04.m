%[text] This script investigates errors when resampling basal data that are likely due to problems in the babelbetes structure.
import AIDIF.constructHiveQueryTable
rootFolder = "/Users/jan/git/aidif/out";
queryTable = constructHiveQueryTable(rootFolder);
fprintf("%d parquet files.",height(queryTable))

uniquePatients = unique(queryTable(:,["study_name","patient_id"]));
fprintf("%d unique patients.",height(uniquePatients))

log = cell(height(uniquePatients),1);
hWaitBar = waitbar(0, 'Processing...');
fprintf("Start processing.",height(uniquePatients))
for iPatient = 1:height(uniquePatients)
    patientID = string(uniquePatients.study_name(iPatient));
    studyName =string(uniquePatients.patient_id(iPatient));
    try
        rowMask = ismember(queryTable(:, {'study_name','patient_id'}), uniquePatients(iPatient,:));
        patientRows = queryTable(rowMask,:);
        basalPath = patientRows(patientRows.data_type=='basal',"path").path;
        rawBasal = parquetread(basalPath, "OutputType", "timetable");
        basalResampled = AIDIF.interpolateBasal(rawBasal);
        result = "success";
    catch exception
        result = exception.message;
    end
    s=struct("study_name", patientID, "patient_id", studyName, "data_type", "basal", "result", result);
    log{iPatient} = s;
    waitbar(iPatient/height(uniquePatients), hWaitBar, sprintf('Patient: %d / %d', iPatient, height(uniquePatients)));
end
%%
%[text] Show the success rates in resampling basal rates per study
logTable = struct2table([log{:}]);
successRates = groupsummary(logTable, "study_name", @(r) mean(strcmp(r, 'success'))*100, "result");
successRates = renamevars(successRates,'fun1_result','successRate');
successRates = sortrows(successRates,'successRate','descend') %[output:99f3f18a]
%%
%[text] Show the error counts per study
errorLogs = logTable(logTable.result ~= 'success',:);
errorSummary = groupsummary(errorLogs, ["study_name", "result"]);
errorSummary = sortrows(errorSummary,'GroupCount','descend') %[output:5df0650c]
%%
%[text] Print one representative example
[G, groups] = findgroups(errorLogs(:, ["study_name", "result"]));
errorExamples = splitapply(@(a,b,c,d) struct('study',a(1),'patient',b(1),'error',d(1)), errorLogs, G);
errorExamples = struct2table(errorExamples);
tmp = strcat(x.study," ", x.patient);
errorExamples %[output:58e421a9]
i = find(tmp(2)==tmp); %[control:dropdown:1b93]{"position":[10,16]}
row = errorExamples(i,:) %[output:2b2d7a6d]
%%
rawPath = queryTable(queryTable.study_name == row.study & ...
                     queryTable.patient_id == row.patient & ...
                     queryTable.data_type == "basal" ,:).path;
rawPath %[output:9980a61d]
raw = parquetread(rawPath, "OutputType", "timetable");
%%
raw %[output:865a13ba]
%%
%[text] Check for sorting
issorted(raw.Properties.RowTimes,'ascend') %[output:1c28e0bb]
jumps = diff(raw.Properties.RowTimes)<0;
jumpsContext = any(horzcat(jumps,[0;jumps(1:end-1)],[jumps(2:end);0]),2);
raw(jumpsContext,:) %[output:6b84ab9f]
%%

bTimeDup = AIDIF.findDuplicates(raw(:,[]));
% Display the duplicates found in the raw data
fprintf("Found %d duplicate timestamps in the raw data.\n", sum(bTimeDup)); %[output:3bed45d9]
raw(bTimeDup,:) %[output:387e23ed]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[control:dropdown:1b93]
%   data: {"defaultValue":"tmp(1)","itemLabels":["DCLP3 59","DCLP5 1","IOBP2 100","Loop 292","Loop 10","PEDAP 1","T1DEXI 1024","T1DEXI 775","T1DEXIP 154"],"items":["tmp(1)","tmp(2)","tmp(3)","tmp(4)","tmp(5)","tmp(6)","tmp(7)","tmp(8)","tmp(9)"],"itemsVariable":"tmp","label":"Drop down","run":"Section"}
%---
%[output:99f3f18a]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study_name","GroupCount","successRate"],"columns":3,"dataTypes":["string","double","double"],"header":"9×3 table","name":"successRates","rows":9,"type":"table","value":[["\"Flair\"","115","100"],["\"ReplaceBG\"","208","100"],["\"DCLP3\"","112","99.1071"],["\"T1DEXI\"","493","98.9858"],["\"T1DEXIP\"","245","97.5510"],["\"IOBP2\"","343","79.8834"],["\"Loop\"","851","74.0306"],["\"PEDAP\"","99","4.0404"],["\"DCLP5\"","100","0"]]}}
%---
%[output:5df0650c]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study_name","result","GroupCount"],"columns":3,"dataTypes":["string","string","double"],"header":"9×3 table","name":"errorSummary","rows":9,"type":"table","value":[["\"Loop\"","\"Invalid argument at position 1. ''basal_rate'' must contain finite, nonnegative numeric values.\"","215"],["\"DCLP5\"","\"Invalid argument at position 1. ''tt''must be sorted ascending by time.\"","100"],["\"PEDAP\"","\"Invalid argument at position 1. ''tt''must be sorted ascending by time.\"","95"],["\"IOBP2\"","\"Invalid argument at position 1. ''tt''must be sorted ascending by time.\"","69"],["\"Loop\"","\"File name must be a string or character vector specifying a parquet file.\"","6"],["\"T1DEXIP\"","\"File name must be a string or character vector specifying a parquet file.\"","6"],["\"T1DEXI\"","\"File name must be a string or character vector specifying a parquet file.\"","4"],["\"DCLP3\"","\"Sample points must be unique.\"","1"],["\"T1DEXI\"","\"Invalid argument at position 1. ''tt'' must contain at least two samples to be resampled.\"","1"]]}}
%---
%[output:58e421a9]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study","patient","error"],"columns":3,"dataTypes":["string","string","string"],"header":"9×3 table","name":"errorExamples","rows":9,"type":"table","value":[["\"DCLP3\"","\"59\"","\"Sample points must be unique.\""],["\"DCLP5\"","\"1\"","\"Invalid argument at position 1. ''tt''must be sorted ascending by time.\""],["\"IOBP2\"","\"100\"","\"Invalid argument at position 1. ''tt''must be sorted ascending by time.\""],["\"Loop\"","\"292\"","\"File name must be a string or character vector specifying a parquet file.\""],["\"Loop\"","\"10\"","\"Invalid argument at position 1. ''basal_rate'' must contain finite, nonnegative numeric values.\""],["\"PEDAP\"","\"1\"","\"Invalid argument at position 1. ''tt''must be sorted ascending by time.\""],["\"T1DEXI\"","\"1024\"","\"File name must be a string or character vector specifying a parquet file.\""],["\"T1DEXI\"","\"775\"","\"Invalid argument at position 1. ''tt'' must contain at least two samples to be resampled.\""],["\"T1DEXIP\"","\"154\"","\"File name must be a string or character vector specifying a parquet file.\""]]}}
%---
%[output:2b2d7a6d]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study","patient","error"],"columns":3,"dataTypes":["string","string","string"],"header":"1×3 table","name":"row","rows":1,"type":"table","value":[["\"DCLP5\"","\"1\"","\"Invalid argument at position 1. ''tt''must be sorted ascending by time.\""]]}}
%---
%[output:9980a61d]
%   data: {"dataType":"textualVariable","outputData":{"name":"rawPath","value":"\"\/Users\/jan\/git\/aidif\/out\/study_name=DCLP5\/data_type=basal\/patient_id=1\/6b7ddcfb55684152940a6ba5715b2f7d-0.parquet\""}}
%---
%[output:865a13ba]
%   data: {"dataType":"tabular","outputData":{"columnNames":["datetime","basal_rate"],"columns":2,"dataTypes":["datetime","double"],"header":"20655×1 timetable","name":"raw","rows":20655,"type":"timetable","value":[["15-Nov-2018 14:12:45","0"],["15-Nov-2018 14:42:47","0.3250"],["15-Nov-2018 15:02:47","0.3000"],["17-Nov-2018 11:04:40","0.6500"],["19-Nov-2018 11:03:32","0.6500"],["21-Nov-2018 11:02:50","0.6500"],["19-Nov-2018 12:12:31","0"],["19-Nov-2018 12:37:30","0.6500"],["19-Nov-2018 13:47:33","0"],["21-Nov-2018 12:12:21","0"],["21-Nov-2018 12:17:21","0.6500"],["15-Nov-2018 17:03:23","0.3250"],["19-Nov-2018 14:02:35","0.6500"],["19-Nov-2018 15:02:38","0.6000"]]}}
%---
%[output:1c28e0bb]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   0\n"}}
%---
%[output:6b84ab9f]
%   data: {"dataType":"tabular","outputData":{"columnNames":["datetime","basal_rate"],"columns":2,"dataTypes":["datetime","double"],"header":"11317×1 timetable","name":"ans","rows":11317,"type":"timetable","value":[["19-Nov-2018 11:03:32","0.6500"],["21-Nov-2018 11:02:50","0.6500"],["19-Nov-2018 12:12:31","0"],["21-Nov-2018 12:12:21","0"],["21-Nov-2018 12:17:21","0.6500"],["15-Nov-2018 17:03:23","0.3250"],["21-Nov-2018 14:02:35","0"],["21-Nov-2018 14:11:25","0.6500"],["19-Nov-2018 17:02:47","0.6500"],["21-Nov-2018 15:27:20","0"],["21-Nov-2018 15:43:15","0.6000"],["17-Nov-2018 15:00:34","0.6000"],["17-Nov-2018 16:02:39","0.6000"],["17-Nov-2018 17:02:43","0.6500"]]}}
%---
%[output:3bed45d9]
%   data: {"dataType":"text","outputData":{"text":"Found 0 duplicate timestamps in the raw data.\n","truncated":false}}
%---
%[output:387e23ed]
%   data: {"dataType":"text","outputData":{"text":"\nans =\n\n  0×1 empty <a href=\"matlab:helpPopup('timetable')\" style=\"font-weight:bold\">timetable<\/a>\n\n    <strong>datetime<\/strong>    <strong>basal_rate<\/strong>\n    <strong>________<\/strong>    <strong>__________<\/strong>\n\n\n","truncated":false}}
%---
