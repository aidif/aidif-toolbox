%[text] ## **Catching Babelbetes Errors**
%[text] ### **AIDIF**
%[text] #### Author: Jan Wrede
%[text] #### Date created: 2025-12-02
%[text] <u>Abstract</u>: 
%%
%[text] <u>Process:</u> 
rootFolder = "/Users/jan/git/nudgebg/babelbetes/data/out/2025-11-04 - 12ee1ad";
queryTable = AIDIF.constructHiveQueryTable(rootFolder);
queryTable = sortrows(queryTable,["study_name","patient_id"]);
fprintf("There are %d rows",height(queryTable));
%[text] Filter
%%
DATA_TYPES = ["all", "cgm","bolus","basal"];
STUDY_NAMES = ["all"; unique(queryTable.study_name)];
%[text] Pre-process bolus timetables
studies = STUDY_NAMES(1); %[control:dropdown:77ce]{"position":[11,25]}
if studies == "all"
    studies = STUDY_NAMES(2:end);
end
data_types = DATA_TYPES(1); %[control:dropdown:0cdb]{"position":[14,27]}
if data_types == "all"
    data_types = DATA_TYPES(2:end);
end
queryTableFiltered = queryTable(ismember(queryTable.study_name, studies) & ismember(queryTable.data_type, data_types),:);
fprintf("Processing %s for %s ",data_types,strjoin(studies',","))
fprintf("Processing %i rows (%i patients) for %i studies and %i data types", ...
    height(queryTableFiltered), length(unique(queryTableFiltered.patient_id)),...
    length(unique(queryTableFiltered.study_name)), ...
    length(unique(queryTableFiltered.data_type)));
%%
patients = unique(queryTableFiltered(:,["study_name","patient_id"]));
numPatients = height(patients);

TT = table('Size', [numPatients*length(data_types),7], ...
    'VariableNames', ["study", "patient","dataType","result","errorMessage","raw","resampled"],...
    'VariableTypes',["string", "string","string","string","string","cell","cell"]);
hWaitBar = waitbar(0,"Processing Patients");
for iPatient = 1:numPatients
    waitbar(iPatient/numPatients,hWaitBar);

    rowMask = ismember(queryTableFiltered(:, {'study_name','patient_id'}), patients(iPatient,:));
    rows = queryTableFiltered(rowMask,:);
    
    patient = string(patients.patient_id(iPatient));
    study = string(patients.study_name(iPatient));
    
    for iType = 1:1:length(data_types)
        dataType = data_types(iType);
        indexRow = (iPatient-1)*(length(data_types))+iType;
        TT{indexRow,["study","patient","dataType"]} = [study,patient,dataType];
        result = "success";
        errorMessage = "";
        try
            if any(ismember(rows.data_type, dataType))
                path = rows(rows.data_type==dataType,"path").path;
                tt = parquetread(path, "OutputType", "timetable");
                TT{indexRow,"raw"} = {tt};

                switch dataType
                    case "bolus"
                        durationBase = AIDIF.FIX_parquetDuration(path,'delivery_duration');
                        tt.delivery_duration = milliseconds(tt.delivery_duration/durationBase);
                        ttResampled = AIDIF.interpolateBolus(tt);
                    case "cgm"
                        tt.cgm = double(tt.cgm);% parquet sometimes stores as int64
                        ttResampled = AIDIF.interpolateCGM(tt);
                    case "basal"
                        ttResampled = AIDIF.interpolateBasal(tt);
                end
                TT{indexRow,"resampled"} = {ttResampled};
            else
                error(AIDIF.Constants.ERROR_ID_MISSING_FILE, "No %s file found",dataType);
            end
        catch exception
            result = exception.identifier;
            errorMessage = exception.message;
        end
        TT{indexRow,"result"} = {result};
        TT{indexRow,"errorMessage"} = {errorMessage};
    end
end
close(hWaitBar)
%[text] ### Show result counts and rates
%success percentage
studyRates = groupsummary(TT, ["study"], @(r) mean(strcmp(r, 'success'))*100, "result");
studyRates.Properties.VariableNames{3} = 'Success Rate';
sortrows(studyRates, "Success Rate", "descend")
%error counts
resultCounts = groupsummary(TT,["study", "dataType", "result"]);
resultCounts = sortrows(resultCounts,["GroupCount"], "descend")
%detailed error messages
sortrows(groupsummary(TT(TT.result ~= "success",:), ["study", "dataType", "result","errorMessage"]),"GroupCount","descend")
%[text] ### Show Representative examples
errorLogs = TT(TT.result ~= "success",["study","patient","dataType","result"]);
[G, groups] = findgroups(errorLogs(:, ["study", "result", "dataType"]));
errorExamples = splitapply(@(a,b,c,d) struct('study',a(1), 'patient',b(1), 'type',c(1), 'result',d(1)), errorLogs, G);
errorExamples = struct2table(errorExamples);
errorExamples
%%
%[text] ### Further Investigation
%[text] Below are just script pieces that can be used for investigation
function bOverlap = findOverlaps(tt)
    bOverlap = tt.Properties.RowTimes(2:end)<(tt.Properties.RowTimes(1:end-1)+tt.delivery_duration(1:end-1));
end

tmp = strcat(errorExamples.study," ", errorExamples.patient, " ", errorExamples.type, " ", errorExamples.result);
j = find(tmp(1)==tmp); %[control:dropdown:50f1]{"position":[10,16]}
row = errorExamples(j,:);
%%
ttRaw = TT{TT.study == row.study  & TT.patient == row.patient & queryTable.data_type == row.type,"raw"}{1}
rawPath = queryTable(queryTable.study_name == row.study & ...
                     queryTable.patient_id == row.patient & ...
                     queryTable.data_type == row.type,:).path;
tt = parquetread(rawPath, "OutputType", "timetable");
base = AIDIF.readParquetDurationBase(rawPath,'delivery_duration');
tt.delivery_duration = milliseconds(tt.delivery_duration/base);
tt
%%
%[text] ### non positive durations?
sum(raw.delivery_duration>0)
raw(raw.delivery_duration<0,:)
sum(isnan(raw.delivery_duration))
AIDIF.interpolateBolus(raw) %[output:501b3ac7] %[output:5f5a0a01] %[output:51353c81]
%[text] 
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[control:dropdown:77ce]
%   data: {"defaultValue":"STUDY_NAMES(1)","itemLabels":["all","DCLP3","DCLP5","Flair","IOBP2","Loop","ReplaceBG","T1DEXI"],"items":["STUDY_NAMES(1)","STUDY_NAMES(2)","STUDY_NAMES(3)","STUDY_NAMES(4)","STUDY_NAMES(5)","STUDY_NAMES(6)","STUDY_NAMES(7)","STUDY_NAMES(8)"],"itemsVariable":"STUDY_NAMES","label":"Drop down","run":"Section"}
%---
%[control:dropdown:0cdb]
%   data: {"defaultValue":"DATA_TYPES(1)","itemLabels":["all","cgm","bolus","basal"],"items":["DATA_TYPES(1)","DATA_TYPES(2)","DATA_TYPES(3)","DATA_TYPES(4)"],"itemsVariable":"DATA_TYPES","label":"Drop down","run":"Section"}
%---
%[control:dropdown:50f1]
%   data: {"defaultValue":"tmp(1)","itemLabels":["   "],"items":["tmp(1)"],"itemsVariable":"tmp","label":"Drop down","run":"Section"}
%---
%[output:501b3ac7]
%   data: {"dataType":"textualVariable","outputData":{"name":"g","value":"\"success\""}}
%---
%[output:5f5a0a01]
%   data: {"dataType":"textualVariable","outputData":{"name":"c","value":"6222"}}
%---
%[output:51353c81]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study","patient","GroupCount","startGap","endGap","overlap"],"columns":6,"dataTypes":["string","string","double","double","double","double"],"header":"2074×6 table","name":"gaps","rows":2074,"type":"table","value":[["\"DCLP3\"","\"10\"","3","-0.0115","0.1513","198.3002"],["\"DCLP3\"","\"100\"","3","-0.0222","0.0027","182.0444"],["\"DCLP3\"","\"102\"","3","-0.0243","0.0300","207.4781"],["\"DCLP3\"","\"105\"","3","-0.0896","0.1270","175.6835"],["\"DCLP3\"","\"111\"","3","-0.1502","0.3671","188.2775"],["\"DCLP3\"","\"114\"","3","-0.0649","-0.0825","198.8269"],["\"DCLP3\"","\"115\"","3","-0.0373","-0.0764","187.0981"],["\"DCLP3\"","\"116\"","3","-0.0050","-0.1163","182.7271"],["\"DCLP3\"","\"117\"","3","-0.0031","-0.0843","188.2428"],["\"DCLP3\"","\"118\"","3","-0.0113","-0.1076","177.6088"],["\"DCLP3\"","\"120\"","3","-0.0156","-0.1235","187.0791"],["\"DCLP3\"","\"121\"","3","-0.0200","-0.0218","181.8396"],["\"DCLP3\"","\"122\"","3","-0.0173","0.0270","182.3085"],["\"DCLP3\"","\"123\"","3","-0.0497","0.0799","176.4038"]]}}
%---
