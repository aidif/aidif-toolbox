%[text] The object of this research script is to review the export of combined data files and verify whether the minimum requirements are achieved:
%[text] - at least 10K patient days for data
%[text] - cross section of data from each of the **five** studies with largely adult patients (Loop, Replace BG, Flair, IOBP2, and DCLP5)
%[text] - 20% of patient days for each of the above studies is sufficient \
%[text] Create query tables for both the raw and combined babelbetes datafiles
envVars = loadenv("local.env");
rawQuery = AIDIF.constructHiveQueryTable(envVars("DATA_IMPORT_RAW_PATH"));
finalQuery = AIDIF.constructHiveQueryTable(envVars("DATA_IMPORT_COMBINED_PATH"));
%%
%[text] Use the file query to import the combined data and analyze

for i = 1:height(finalQuery)
    data = parquetread(finalQuery.path(i),"OutputType","timetable");
    data{:,'elapsedTime'} = [diff(data.Properties.RowTimes);0];
    data(any(isnan(data{:,["egv" "totalInsulin"]}),2),:) = [];

    patientDurations(i,:) = days(sum(data.elapsedTime));
end
%%
%[text] Now, complete some statistics and see how they compare to the minimum requirements
%[text] First, look at patient counts:
uniqueRaw = unique(rawQuery(:,["study_name" "patient_id"]),"rows","stable");
rawStudyPatientCount = groupsummary(uniqueRaw,"study_name");
finalStudyPatientCount = groupsummary(finalQuery,"study_name");
studyPatientCount = join(rawStudyPatientCount,finalStudyPatientCount,"Keys","study_name");
studyPatientCount = renamevars(studyPatientCount,[2 3],["rawCount" "finalCount"]);
studyPatientCount{end+1,"study_name"} = "total"; %[output:3f25dfbf]
studyPatientCount{end,["rawCount" "finalCount"]} = [sum(studyPatientCount.rawCount) sum(studyPatientCount.finalCount)];
studyPatientCount{:,"difference"} = studyPatientCount.rawCount - studyPatientCount.finalCount;
studyPatientCount{:,'percentage'} = (studyPatientCount.finalCount./studyPatientCount.rawCount)*100 %[output:8f302586]
%[text] Looking only at the relevant studies for current minimum requirements.
relevantStudies = ["Loop" "ReplaceBG" "Flair" "IOBP2" "DCLP5"];
studyPatientCount = studyPatientCount(ismember(studyPatientCount.study_name,[relevantStudies "total"]),:);
studyPatientCount{studyPatientCount.study_name == "total",2:end} = 0;
studyPatientCount{studyPatientCount.study_name == "total",["rawCount" "finalCount" "difference" "percentage"]} = ... %[output:group:7dde70a9] %[output:86be0a2b]
    [sum(studyPatientCount.rawCount) sum(studyPatientCount.finalCount) sum(studyPatientCount.difference) sum(studyPatientCount.finalCount)/sum(studyPatientCount.rawCount)*100] %[output:group:7dde70a9] %[output:86be0a2b]
%[text] This table represents the total patient count from each study that was collected at this time.
%%
%[text] Now, collect statistics on the total data duration in days.
studyDays = table(finalQuery.study_name,finalQuery.patient_id,patientDurations,'VariableNames',["study_name" "patient_id" "dayDuration"]);
studyDays = studyDays(ismember(studyDays.study_name,relevantStudies),:);
daysSummary = groupsummary(studyDays(:,["study_name" "dayDuration"]),"study_name",["sum" "mean" "std"]);
totalTimeInDays = sum(studyDays.dayDuration);
fprintf("the total duration of data in days is %.0f days",totalTimeInDays) %[output:3ececbb6]
studyDayPercentage = (daysSummary.sum_dayDuration./totalTimeInDays)*100;
daysSummary{:,"totalPercentage"} = studyDayPercentage %[output:6a5b1c8b]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:3f25dfbf]
%   data: {"dataType":"warning","outputData":{"text":"Warning: The assignment added rows to the table, but did not assign values to all of the table's existing variables. Those variables are extended with rows containing default values."}}
%---
%[output:8f302586]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study_name","rawCount","finalCount","difference","percentage"],"columns":5,"dataTypes":["string","double","double","double","double"],"header":"10×5 table","name":"studyPatientCount","rows":10,"type":"table","value":[["\"DCLP3\"","112","110","2","98.2143"],["\"DCLP5\"","100","99","1","99"],["\"Flair\"","115","83","32","72.1739"],["\"IOBP2\"","343","343","0","100"],["\"Loop\"","851","845","6","99.2949"],["\"PEDAP\"","99","20","79","20.2020"],["\"ReplaceBG\"","208","91","117","43.7500"],["\"T1DEXI\"","493","332","161","67.3428"],["\"T1DEXIP\"","245","189","56","77.1429"],["\"total\"","2566","2112","454","82.3071"]]}}
%---
%[output:86be0a2b]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study_name","rawCount","finalCount","difference","percentage"],"columns":5,"dataTypes":["string","double","double","double","double"],"header":"6×5 table","name":"studyPatientCount","rows":6,"type":"table","value":[["\"DCLP5\"","100","99","1","99"],["\"Flair\"","115","83","32","72.1739"],["\"IOBP2\"","343","343","0","100"],["\"Loop\"","851","845","6","99.2949"],["\"ReplaceBG\"","208","91","117","43.7500"],["\"total\"","1617","1461","156","90.3525"]]}}
%---
%[output:3ececbb6]
%   data: {"dataType":"text","outputData":{"text":"the total duration of data in days is 341986 days","truncated":false}}
%---
%[output:6a5b1c8b]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study_name","GroupCount","sum_dayDuration","mean_dayDuration","std_dayDuration","totalPercentage"],"columns":6,"dataTypes":["string","double","double","double","double","double"],"header":"5×6 table","name":"daysSummary","rows":5,"type":"table","value":[["\"DCLP5\"","99","1.8998e+04","191.9038","53.6858","5.5553"],["\"Flair\"","83","1.3802e+04","166.2883","31.8061","4.0358"],["\"IOBP2\"","343","2.8487e+04","83.0521","19.7116","8.3298"],["\"Loop\"","845","2.6135e+05","309.2917","115.5727","76.4217"],["\"ReplaceBG\"","91","1.9347e+04","212.6070","42.8790","5.6573"]]}}
%---
