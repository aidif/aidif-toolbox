%[text] ## **Catching Babelbetes Errors**
%[text] ### **AIDIF**
%[text] #### Author: Jan Wrede
%[text] #### Date created: 2025-11-08
%[text] <u>Abstract</u>: 
%%
%[text] <u>Process:</u> 
rootFolder = "/Users/jan/git/nudgebg/babelbetes/data/out/2025-11-19";
queryTable = AIDIF.constructHiveQueryTable(rootFolder);
fprintf("There are %d rows",height(queryTable)) %[output:6ee42923]
patients = unique(queryTable(:,["study_name","patient_id"]));
fprintf("There are %d unique patients",height(patients)); %[output:3762b8f9]
%[text] Pre-process bolus timetables
DATA_TYPES = "bolus";
hWaitBar = waitbar(0,"Processing Patients"); %[output:481fe33c]

logs = cell(height(patients),3);
TT = table('Size', [height(patients),6], ...
    'VariableNames', ["study", "patient","dataType","result","raw","resampled"],...
    'VariableTypes',["string", "string","string","string","cell","cell"]);

for iPatient = 1:height(patients) %[output:group:3dffb606]
    waitbar(iPatient/height(patients),hWaitBar); %[output:481fe33c]

    rowMask = ismember(queryTable(:, {'study_name','patient_id'}), patients(iPatient,:));
    rows = queryTable(rowMask,:);
    
    patient = string(patients.patient_id(iPatient));
    study = string(patients.study_name(iPatient));
    TT{iPatient,"study"} = study;
    TT{iPatient,"patient"} = patient;

    if ~all(ismember(rows.data_type,["basal","bolus","cgm"]))
        warning("Patient %s from study %s has missing data.", patient, study)
    end
    for iType = 1:1:length(DATA_TYPES)
        dataType = DATA_TYPES(iType);
        TT{iPatient,"dataType"} = dataType;

        try
            if any(ismember(rows.data_type,dataType))
                path = rows(rows.data_type==dataType,"path").path;
                tt = parquetread(path, "OutputType", "timetable");

                durationBase = AIDIF.readParquetDurationBase(path,'delivery_duration');
                tt.delivery_duration = milliseconds(tt.delivery_duration/durationBase);
                
                TT{iPatient,"raw"} = {tt};

                ttResampled = AIDIF.interpolateBolus(tt);
                TT{iPatient,"resampled"} = {ttResampled};
                result = "success";
            else
                error("No %s file found",dataType);
            end
        catch exception
            result = exception.identifier;
        end
        
        TT{iPatient,"result"} = string(result);
        
        s=struct("study_name", study, "patient_id", patient, "data_type", dataType, "result", result);
        logs{iPatient,iType} = s;
    end
end %[output:group:3dffb606]
%%
%[text] ### Show result counts and rates
resultCounts = groupsummary(TT, ["study", "dataType", "result"]);
resultCounts = sortrows(resultCounts,["study","dataType"]);
resultCounts %[output:29674b2d]
studyRates = groupsummary(TT, ["study"], @(r) mean(strcmp(r, 'success'))*100, "result");
sortrows(studyRates, "fun1_result") %[output:4a60daa1]
%%
%[text] #### Print representative examples
errorLogs = TT(TT.result ~= "success",["study","patient","dataType","result"]);
[G, groups] = findgroups(errorLogs(:, ["study", "result", "dataType"]));
errorExamples = splitapply(@(a,b,c,d) struct('study',a(1), 'patient',b(1), 'type',c(1), 'result',d(1)), errorLogs, G);
errorExamples = struct2table(errorExamples);
errorExamples %[output:641e6d8c]
%[text] ### Investigate Examples
tmp = strcat(errorExamples.study," ", errorExamples.patient, " ", errorExamples.type, " ", errorExamples.result);
j = find(tmp(1)==tmp); %[control:dropdown:4f7f]{"position":[10,16]}
row = errorExamples(j,:);

%%
ttRaw = TT{TT.study == row.study  & TT.patient == row.patient & queryTable.data_type == row.type,"raw"}{1} %[output:8c366765]
function bOverlap = findOverlaps(tt,column)
    bOverlap = tt.Properties.RowTimes(2:end)<(tt.Properties.RowTimes(1:end-1)+tt.delivery_duration(1:end-1));
    i = find(bOverlap);
end
%%
rawPath = queryTable(queryTable.study_name == row.study & ...
                     queryTable.patient_id == row.patient & ...
                     queryTable.data_type == row.type,:).path;
tt = parquetread(rawPath, "OutputType", "timetable");
base = AIDIF.readParquetDurationBase(rawPath,'delivery_duration');
tt.delivery_duration = milliseconds(tt.delivery_duration/base);
tt %[output:4bf9e41b]
%%
%[text] ### non positive durations?
sum(raw.delivery_duration>0) %[output:3490ccc7]
raw(raw.delivery_duration<0,:)
sum(isnan(raw.delivery_duration))
AIDIF.interpolateBolus(raw)
%[text] Inspect as needed here...
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[control:dropdown:4f7f]
%   data: {"defaultValue":"tmp(1)","itemLabels":["Loop 1063 bolus AIDIF:InvalidInput:DuplicatedValues","Loop 100 bolus AIDIF:InvalidInput:InvalidValueRange","PEDAP 1 bolus AIDIF:InvalidInput:Unsorted","ReplaceBG 105 bolus AIDIF:BusinessLogic:OverlappingDeliveries","T1DEXI 1012 bolus AIDIF:InvalidInput:Unsorted","T1DEXIP 101 bolus AIDIF:InvalidInput:Unsorted"],"items":["tmp(1)","tmp(2)","tmp(3)","tmp(4)","tmp(5)","tmp(6)"],"itemsVariable":"tmp","label":"Drop down","run":"Section"}
%---
%[output:6ee42923]
%   data: {"dataType":"text","outputData":{"text":"There are 2421 rows","truncated":false}}
%---
%[output:3762b8f9]
%   data: {"dataType":"text","outputData":{"text":"There are 2421 unique patients","truncated":false}}
%---
%[output:481fe33c]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAWgAAABLCAIAAADSyIquAAAAB3RJTUUH6QsaDjA5Pzb18QAACxNJREFUeJzt3X9Mk9caB\/Cn0AKtwArCBNtOq\/wSoQ5GdYAyYMpkgLODy2RUBeKKwzgxm5ONbYJThC0uZkumwEANJka2olMJKoYYmIqNw4xJlQi2SBGJChVh8kPa+0dvuF6m3B3mxd3s+\/nrfU97+j6HN\/3mnNMCnP7+fgIAYGH1rAsAgP8\/CA4AYIbgAABmCA4AYIbgAABmCA4AYIbgAABmCA4AYIbgAABmCA4AYIbgAABmCA4AYIbgAABmCA4AYIbgAABmCA4AYIbgAABmCA4AYIbgAABmCA4AYIbgAABmCA4AYMZ91gX8veh0ugcPHliOORyOu7u7UCh8hvVcvXrVzc1twjUMDg62traOntrZ2YnFYhsbmz\/S9+7du93d3Z6enhO7NDxbHPxflcmUmJio1WofbVEqlVlZWc+qnoCAgNzc3GXLlk2s+7Vr1xQKxaMtzs7O+fn5ISEhT+pSUFAQFxfn6+tbXFysVqtPnDjBdMWzZ882NTWpVKqJFQxPC5Yqky0mJkaj0Wg0murqapVKdeDAgQsXLjyrYkpKSsZ5k\/9Be\/bs0Wg09fX1arXa1dX1008\/HefJZWVlbW1tRBQXF\/fFF1+wXuuXX345duzYxGuFpwRLlcnG4\/EEAgERCQSCNWvWFBUVabVaqVT6zTffKBSK0tJSpVI5f\/78gwcP1tbWPnz4MDg4eNWqVZb5f2tra3FxcXt7u0gkUqlUHh4eRKTRaCoqKnp7e1988cXVq1fb2toSkVqtrq6uHh4elslk6enpdnZ2AwMD3333XUNDA5\/Pj4iIiI+P53A4J0+ejImJcXFxyc3NjYmJOX36dGtr66xZs9avX29vb09EtbW1x44dM5lMCQkJP\/3008qVK93c3MaMyM7OzjIib29vhUKRn5\/f29vr6OhYWVlZVVXV398vkUhSU1OlUmlBQQERlZeXT5kyxdra+tKlSzKZjIhu3rxZUlJiMBikUmlKSoqbm1t\/f39BQUF8fPyRI0c6Ojr8\/PwyMjIuXbpUU1Nz+\/btnJycnJyca9eulZSUdHR0iESitLQ0Ly+vSb2Rf2+YcTwzZrP5\/PnzRCSRSO7du3f48OGMjAwOhyMQCHbu3Llr166AgIAFCxbs3bvXspbp7OxMSkq6devWa6+9duPGjfT09MHBwTNnzqSlpfF4PJlMVl5evmbNGrPZfOrUqS1btsydOzciIqKystIyBfjqq68qKirCwsJ8fX3z8vK+\/\/57IiovL9fr9UR05MiRlJSUu3fv+vv7q9XqvLw8Iqqurs7IyCAid3f3zMzM\/fv3d3d3jzOiwcHBn3\/+2d7e3t7e\/vz585s3b\/bw8AgPD29ublapVGaz+fnnnycioVDo4OCg1WqPHz9ORF1dXQkJCW1tbXK5\/PLlyytWrLh9+\/bg4GBFRUVycrLZbPb09CwqKiosLOTz+Q4ODlwud\/r06QMDA2lpaUajcdmyZf39\/StXruzp6fkf3zH4N8w4JltNTU1ycjIRdXR03LlzRyaThYeH63Q6IsrIyFi1apXRaCwrK\/vss88SEhKISCKRbNq0yWAwHDhwwNbWdvfu3Xw+Pyws7N1339XpdLt27YqPj8\/NzSWikJCQt99+u6mpqbGx0cnJSalUOjk5+fj4NDU1EdHly5e9vb2Tk5N5PJ5YLJ4yZcqYwt58882tW7cSUW9v78WLF4mosLBw6dKlX375JRH5+fl98MEHjx1RTk7Oc889ZzKZmpubh4aGsrOzrays7t+\/n56evn79eiISiUSZmZm\/\/fZbamrqzp07o6KiAgICLJcgouLiYhcXlz179nC5XKVSGR4efvToUcvWyXvvvWfZztDr9Vqtdt26dXK5\/M6dOyqVSqfT9fT0xMTExMXFxcbGFhYWDgwM\/A9uFzwegmOyicXixYsXE5GVldWMGTNCQ0O53H\/dhbCwMCLS6XQmk8lyTETz5s0jora2tuvXr8tkMj6fT0QzZ86sqqoaGBhoaWmxsrLasGEDEZlMJiJqaWl5\/fXXf\/jhh8jISLlcHhoaGhcXR0TLly\/funXrK6+8EhISEhYWNvr6owIDAy0Hzs7Ow8PDIyMjLS0tiYmJlsYFCxY8aURBQUEzZswgIoVCIZPJfHx8iCgiIsJoNG7atKmjo+Pq1avj\/ECam5v7+vref\/\/90RZLjBJRQECA5WDatGnt7e2P9pJIJIGBgR999FFJSUlwcHB0dLS7u\/s4V4GnC8Ex2by8vFJTUx\/7kCVBhoeHicjK6j9WkXw+f2hoyMXFxXJqNpu7urosGx9+fn6jb7DIyMh58+ZJpdJTp07V1tbW19cXFRUdPHiwsrIyMTFx4cKFNTU1Go3mk08+0Wg027Zte\/QSYz5GNZvNJpPJstNBRH19fU8aUWxsbFBQ0JjG3Nzc06dPr1ixYunSpX19fdnZ2U\/qPjw8LBaLw8PDLafh4eESicRybNmveSwul7tv376Ghoa6urq6urqysrLS0tL58+c\/6fnwdGGP4y9HKpUSUV1dneX0zJkzPB5v1qxZHh4eFy9efPjwIRGdO3du8eLFRqNx+vTp1tbWCoVCoVDMnTt3\/\/79JpMpLy9v7969sbGx27Zt+\/zzzw0GQ09PT1JSUlNTk1Kp\/Prrr5OSkhobG8cvg8vlzpw507ILQ0QnT55kGsWFCxeWL1+emZn56quv3rhx49GHzGbzo6ezZ8++d+\/eG2+8oVAooqOj1Wr1mMnFGJbu9fX1b731lp+f38aNGw8dOiQUChsaGpgqhD8DM46\/HFdX14SEhO3bt7e2tprN5kOHDq1evVooFKakpBw\/fjwtLe2ll146evSoXC6XSqXr1q3Lzs42mUyurq4VFRUvvPCCVCqdPXt2fn7+0NCQk5NTVVWVl5fX1KlTRSLRjh079Hr9gwcPTpw4ER0d\/V8rWbt27YcffmiZa5w9e5ZpFHPmzKmsrLS1te3s7Dx37hwRHT58WKlUisXi0tJSJyen0We+8847CQkJ6enpgYGBtbW1nZ2dv19GjRKLxXq9fvv27WvXrm1vb9+wYcPChQu1Wq3RaFy0aBFThfBnWI8zh4SnjsPh+Pr6WuYUY9r5fL5cLrdMzhctWuTo6HjlypXh4eGkpKSUlBQOh+Po6LhkyZKurq6urq7IyMjNmzfb2Nj4+Pj4+\/tfuXLl5s2bUVFRWVlZNjY2vr6+zs7OjY2NBoNBJpNt2bJFIBCEhoYODQ39+uuvlj1FlUplbW1NRHK5fOrUqUQUFBRkOSAikUjk7+\/v6ekZGhra3d0tFovT0tJ+\/PFHS4T9vmwHB4cxIwoODr5\/\/77BYPD29s7Ly7O2th4ZGZHL5d7e3n19fR4eHiKRSCQSyWQyoVAYFRWl1+uvX78+Z86c3NzcadOmcTgcLpcrl8tH10pSqdTLy0sikfB4vJGRkSVLlrz88sutra1arVYgEGRlZY2u12AS4Juj8ER5eXl8Pn\/jxo1EtG\/fvm+\/\/baurm6cfQf4+8BSBZ7Iz8\/v448\/bmhoGBkZaWxs3LFjB1IDLDDjAABm+FQFAJghOACAGYIDAJghOACAGYIDAJghOACAGYIDAJghOACAGYIDAJhN8CvnAbtvTazjP8Q9i6fdn1hfAHjqJvZHTDDjAABmCA4AYIbgAABmCA4AYIZfqwcAZphxAAAzBAcAMENwAAAzBAcAMENwAAAzBAcAMENwAAAzBAcAMENwAAAzBAcAMENwAAAzBAcAMENwAAAzBAcAMENwAAAzBAcAMENwAAAzBAcAMENwAAAzBAcAMENwAAAzBAcAMENwAACzfwLEGOY0P2wleQAAAABJRU5ErkJggg==","height":0,"width":0}}
%---
%[output:29674b2d]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study","dataType","result","GroupCount"],"columns":4,"dataTypes":["string","string","string","double"],"header":"15×4 table","name":"resultCounts","rows":15,"type":"table","value":[["\"DCLP3\"","\"bolus\"","\"success\"","112"],["\"DCLP5\"","\"bolus\"","\"success\"","100"],["\"Flair\"","\"bolus\"","\"success\"","115"],["\"IOBP2\"","\"bolus\"","\"success\"","343"],["\"Loop\"","\"bolus\"","\"AIDIF:InvalidInput:DuplicatedValues\"","7"],["\"Loop\"","\"bolus\"","\"AIDIF:InvalidInput:InvalidValueRange\"","98"],["\"Loop\"","\"bolus\"","\"success\"","740"],["\"PEDAP\"","\"bolus\"","\"AIDIF:InvalidInput:Unsorted\"","74"],["\"PEDAP\"","\"bolus\"","\"success\"","25"],["\"ReplaceBG\"","\"bolus\"","\"AIDIF:BusinessLogic:OverlappingDeliveries\"","8"],["\"ReplaceBG\"","\"bolus\"","\"success\"","200"],["\"T1DEXI\"","\"bolus\"","\"AIDIF:InvalidInput:Unsorted\"","192"],["\"T1DEXI\"","\"bolus\"","\"success\"","206"],["\"T1DEXIP\"","\"bolus\"","\"AIDIF:InvalidInput:Unsorted\"","68"]]}}
%---
%[output:4a60daa1]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study","GroupCount","fun1_result"],"columns":3,"dataTypes":["string","double","double"],"header":"9×3 table","name":"ans","rows":9,"type":"table","value":[["\"PEDAP\"","99","25.2525"],["\"T1DEXI\"","398","51.7588"],["\"T1DEXIP\"","201","66.1692"],["\"Loop\"","845","87.5740"],["\"ReplaceBG\"","208","96.1538"],["\"DCLP3\"","112","100"],["\"DCLP5\"","100","100"],["\"Flair\"","115","100"],["\"IOBP2\"","343","100"]]}}
%---
%[output:641e6d8c]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study","patient","type","result"],"columns":4,"dataTypes":["string","string","string","string"],"header":"6×4 table","name":"errorExamples","rows":6,"type":"table","value":[["\"Loop\"","\"1063\"","\"bolus\"","\"AIDIF:InvalidInput:DuplicatedValues\""],["\"Loop\"","\"100\"","\"bolus\"","\"AIDIF:InvalidInput:InvalidValueRange\""],["\"PEDAP\"","\"1\"","\"bolus\"","\"AIDIF:InvalidInput:Unsorted\""],["\"ReplaceBG\"","\"105\"","\"bolus\"","\"AIDIF:BusinessLogic:OverlappingDeliveries\""],["\"T1DEXI\"","\"1012\"","\"bolus\"","\"AIDIF:InvalidInput:Unsorted\""],["\"T1DEXIP\"","\"101\"","\"bolus\"","\"AIDIF:InvalidInput:Unsorted\""]]}}
%---
%[output:8c366765]
%   data: {"dataType":"tabular","outputData":{"columnNames":["datetime","bolus","delivery_duration"],"columns":3,"dataTypes":["datetime","double","duration"],"header":"4209×2 timetable","name":"ttRaw","rows":4209,"type":"timetable","value":[["02-Jan-2019 21:15:13","0.4000","0 sec"],["03-Jan-2019 04:46:32","0.5000","0 sec"],["03-Jan-2019 07:37:29","1.8500","0 sec"],["03-Jan-2019 15:30:28","0.3500","0 sec"],["03-Jan-2019 18:02:51","0.1500","0 sec"],["03-Jan-2019 18:02:51","2.9000","1800 sec"],["04-Jan-2019 07:02:53","2.7000","0 sec"],["04-Jan-2019 07:02:53","0.6000","3600 sec"],["04-Jan-2019 10:47:45","1.2000","0 sec"],["04-Jan-2019 11:43:35","0.3000","0 sec"],["04-Jan-2019 13:07:52","0.5500","0 sec"],["04-Jan-2019 16:12:58","1.4000","0 sec"],["04-Jan-2019 18:31:27","0.4500","0 sec"],["04-Jan-2019 18:41:49","0.4000","0 sec"]]}}
%---
%[output:4bf9e41b]
%   data: {"dataType":"tabular","outputData":{"columnNames":["datetime","bolus","delivery_duration"],"columns":3,"dataTypes":["datetime","double","duration"],"header":"4209×2 timetable","name":"tt","rows":4209,"type":"timetable","value":[["02-Jan-2019 21:15:13","0.4000","0 sec"],["03-Jan-2019 04:46:32","0.5000","0 sec"],["03-Jan-2019 07:37:29","1.8500","0 sec"],["03-Jan-2019 15:30:28","0.3500","0 sec"],["03-Jan-2019 18:02:51","0.1500","0 sec"],["03-Jan-2019 18:02:51","2.9000","1800 sec"],["04-Jan-2019 07:02:53","2.7000","0 sec"],["04-Jan-2019 07:02:53","0.6000","3600 sec"],["04-Jan-2019 10:47:45","1.2000","0 sec"],["04-Jan-2019 11:43:35","0.3000","0 sec"],["04-Jan-2019 13:07:52","0.5500","0 sec"],["04-Jan-2019 16:12:58","1.4000","0 sec"],["04-Jan-2019 18:31:27","0.4500","0 sec"],["04-Jan-2019 18:41:49","0.4000","0 sec"]]}}
%---
%[output:3490ccc7]
%   data: {"dataType":"error","outputData":{"errorType":"runtime","text":"Unable to resolve the name 'raw.delivery_duration'."}}
%---
