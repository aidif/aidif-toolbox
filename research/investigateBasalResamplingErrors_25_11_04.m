%% create the import query table for babelbetes hive schema
%assign root folder for babelbetes data partition in rootFolder variable
rootFolder = "/Users/jan/git/nudgebg/babelbetes/data/out/2025-11-11 - improved basal";
queryTable = AIDIF.constructHiveQueryTable(rootFolder);
fprintf("There are %d rows\n", height(queryTable)) %[output:9f591bc0]
%%

%% ingest babelbetes data, by study and subject, for all data types.
patients = unique(queryTable(:,["study_name","patient_id"]));
sprintf("with %d unique patients\n",height(patients));

logs = cell(height(patients),3);
f = waitbar(0,"Processing Patients"); %[output:958c9efc]
dataType = 'basal';

for iPatient = 1:height(patients)     %[output:group:7f507982]
    rowMask = ismember(queryTable(:, {'study_name','patient_id'}), patients(iPatient,:));
    rows = queryTable(rowMask,:);
    
    patient = string(patients.patient_id(iPatient));
    study = string(patients.study_name(iPatient));

    if ~all(ismember(rows.data_type,["basal","bolus","cgm"]))
        warning("Patient %s from study %s has missing data.", patient, study)
    end
    
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
        result = exception.message;
    end

     s=struct("study_name", study, "patient_id", patient, "data_type", dataType, "result", result);
     logs{iPatient} = s;
     waitbar(iPatient/height(patients),f,"Processing Patients"); %[output:958c9efc]
end %[output:group:7f507982]
%%
logTable = struct2table([logs{:}]);
errorLogTable = logTable(logTable.result~="success",:);
errorCounts = groupsummary(errorLogTable , ["study_name", "data_type", "result"]);
sortrows(errorCounts,"GroupCount") %[output:605acbef]
sortrows(groupsummary(logTable, "study_name", @(r) mean(strcmp(r, 'success'))*100, "result"),"fun1_result") %[output:67065f61]
%%
%[text] ### Show and investigate examples
[G, ~] = findgroups(errorLogTable(:, ["study_name", "result", "data_type"]));
errorExamples = splitapply(@(a,b,c,d) struct('study',a(1), 'patient',b(1), 'type',c(1), 'error',d(1)), errorLogTable, G);
errorExamples = struct2table(errorExamples);
errorExamples %[output:87a5034c]
%%
tmp = strcat(errorExamples.study," ", errorExamples.patient, " ", errorExamples.type);
j = find(tmp(1)==tmp); %[control:dropdown:72bc]{"position":[10,16]}
row = errorExamples(j,:);
rawPath = queryTable(queryTable.study_name == row.study & ...
                     queryTable.patient_id == row.patient & ...
                     queryTable.data_type == row.type,:).path;
rawPath %[output:08079044]
%%
raw = parquetread(rawPath, "OutputType", "timetable");
%sorted
issorted(raw.Properties.RowTimes,'ascend') %[output:859bf8a7]
%positive
all(raw.basal_rate >= 0) %[output:70d19842]
%nan
sum(isnan(raw.basal_rate)) %[output:21a710e0]

%finite
all(isfinite(raw.basal_rate)) %[output:1477310d]
%duplicates
raw(AIDIF.findDuplicates(raw(:,[])),:) %[output:1ed35948]
%%
%[text] Print one representative example


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[control:dropdown:72bc]
%   data: {"defaultValue":"tmp(1)","itemLabels":["T1DEXI 775 basal"],"items":["tmp(1)"],"itemsVariable":"tmp","label":"Drop down","run":"Section"}
%---
%[output:9f591bc0]
%   data: {"dataType":"text","outputData":{"text":"There are 2570 rows\n","truncated":false}}
%---
%[output:958c9efc]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAWgAAABLCAIAAADSyIquAAAAB3RJTUUH6QsMESgSc5l45gAACuNJREFUeJzt3X9UU\/Ufx\/E3PwZB07EjZGEQA48TCDA4IZKHn0bJoqgT\/jiEhoklnpN1+qEea6cswbTS8KgZh1NGQIvyR2GcI4K5AW3QDrjJYAsEGUN+hYFzTJjb9497Dsdjan3MoO\/p9fjrbnh3P9edPbmfz4WDk0gkIgAAFs7TPQAA+P+DcAAAM4QDAJghHADADOEAAGYIBwAwQzgAgBnCAQDMEA4AYIZwAAAzhAMAmCEcAMAM4QAAZggHADBDOACAGcIBAMwQDgBghnAAADOEAwCYIRwAwAzhAABmCAcAMHOd7gH8t4SHh\/P5fG7bbrd3dnb29\/dP43gWLlzY1dV122Pw9PRcsGDB5EOLxaLX68fGxv7Kvr6+vr6+vr\/88svtHRqmlxP+rspUkslkAoHg2mfq6uree++96RpPZWVlUVHRt99+e3u7R0VFbd++\/dpnxsfHd+7cWVtbe7NdNm7cePr06ebm5szMzIyMjPT0dKYjRkdHR0VFHThw4PYGDHcKrjimWlNT044dO4jIx8fn6aefTk5OTk5Orq6unpbB7Ny502Aw\/M0X2bdvn1wud3FxCQoKWr9+\/euvv36LcCxdutRoNDY3N9fW1nZ3d7Mea968eY8++ijCMe0Qjqk2MTExMjJCRCMjI5999llycvLs2bP9\/f3XrFlz8uTJFStWHDly5NSpU1lZWbGxsa6urg0NDYcOHbJarUQUEhLy3HPPPfDAA93d3cXFxTqdjohiY2MlEolQKFSr1WVlZRaLhYiWLVuWlJTE4\/G0Wm1hYeHly5f5fH52dnZkZOTY2JhCoSgrKyOihx9++NKlSyaT6e2331YqleHh4cHBwXq9vrCw8PfffyeixMTExx9\/3NXV9ejRoxERERUVFV1dXdedkcVi4c5oeHh47ty5q1ev9vHxGRwcfPLJJ1NSUvh8\/rlz52QymV6v37JlCxE99thjQ0NDNpstKipKoVAQUWBg4LJlywIDA3U63dGjR7u6ugQCwSuvvPLTTz898sgjIpFIq9V++umnUVFRCQkJ7u7uUql027ZtoaGhmZmZfn5+RqOxtLT07NmzU\/g2\/tdhcXQ6xcXFEZHZbPbx8YmJidmyZYvD4TCbzW+++eby5csbGhpqa2vT0tK2bdtGRCKRaNeuXQKBoKKiYtasWdu3b\/fw8EhJSZFKpWNjYw0NDampqXv27CGi1NTUNWvWNDU1VVdXL168WCqVEtHLL7+clJRUXV2t0WiysrJWrlxJRImJiQEBAUQUGxv72muvCYVClUqVmJj4xhtvENHSpUs3bdpkt9s7Ojo2b978xBNP3Hfffbc4HU9Pz\/Dw8KtXr\/72229xcXG5ubkGg+HEiRN+fn7cRdb58+eJaGho6OLFiyKRKCEhgYj8\/f0LCgruv\/9+uVweHBy8Z88ePz8\/Pp+\/aNEi7j9Eq9WmpqauXbv20qVLw8PD3Hg8PT3z8\/Pd3d0rKirc3Nw++OCD2bNn\/6NvFlwLVxxTLTIy8quvviKiGTNmuLu7m0ymysrK8PBwIjp8+HBRUdG9994bHx9\/6NChr7\/+mohGR0dzcnLEYnFaWprdbt+0aZPZbG5ubs7Pzw8LC3vhhRdqa2vff\/99IjIYDFKpNCYmJiAgYHx8\/NixY319fW1tbWFhYUQUGhra09NTXl5+5cqV\/v7+0dHR6wb2888\/v\/vuu0QkFAqjo6OJaNWqVWq1euvWrURkNBo3bNhwwzPKzc3Nzs52dnb28vJydnYuKyuz2+0eHh7V1dUFBQVEZLFYXnrpJYFAUFpayr2mVqvlTpmIMjMzzWbzq6++OjExcfjw4fLy8iVLlpw4cYKIjh07xs1KxGJxaGjo\/v37NRrN3LlzS0pKIiIi3NzcGhsbZTJZZWXlihUrPDw8\/oG3C24M4Zhq\/f39NTU1RORwOEZGRqqqqiYmJrgvqVQqIhKLxU5OTtw2EWk0GiISiURisbi7u9tsNhNRa2treno6n88XCATz58\/nPp\/Ozs5E5OfnV1dXJ5FIPv\/8c6PRqFAouA\/hjz\/+mJWV9d133+l0OqVSWV9ff93AuIkPEfX29rq6urq4uHh5eXFHJ6Jb3P5obm4+d+4cEdlstvb2drVaTUSnTp0SCoW7du3y9fUVCoVE5OTkdMPdQ0JC3N3dP\/roo8lnJhfsJ9dfTCbTdav4LS0tXV1dzz\/\/\/DPPPMOdzh\/nUPDPQTimmslkKikpueGXbDYbEfF4vMntSVarlcfj9fX1TT4TFBTELXx0dnZOTu8VCsWZM2cMBsOqVavi4uIiIiKWL1+elpa2cuXKkpISlUoVHR29cOHCnJycyMjIt95669pDXL169dqHXIYmo8Z9+G+ovr7+j4u7Uqn0oYceOn78uEKhuOeee5599tmb7e7i4jI4OFhXV8c9rKur6+3t5bbHx8e5DYfDcd1eNpstNzc3Pj5+\/vz5cXFxKSkpeXl5crn8ZkeBOwtrHP863LfZmJgY7uGiRYscDodOp9Pr9aGhoW5ubkSUnJy8b9++WbNmjY2NWa1WmUwmk8na2toyMjLuvvvuvLy8tWvXHjly5J133jl48ODMmTN9fX2\/+eabefPmlZaWbty4saqqKjg4+NbDmJiYuHz5MjfNISJuPeKvCw8Pr6qq2r9\/\/\/fff3\/rSUR7e\/vMmTPLy8tlMtkPP\/wgkUjmzJnzp6+fkpJSVlamUqkOHDiwevVqm83m7+\/PNEL4O3DF8a\/T3d2tUqmys7N9fHycnJwkEklNTc3AwEB5efnixYsLCgoaGxslEklHR4dGoykuLl63bt3WrVsvXLiQlpZ24cKFM2fOBAcHZ2VlWa3WixcvJiUlDQwMGI3Gzs7OnJwcb29vDw+P+Ph4pVL5pyMpLi5ev349N4n409Bcp729PSkpyWKxiESiBx98kIjS09O\/+OILi8WSmppqMpkm\/2VpaenHH3\/8ySefNDQ0JCQkCAQCuVx+s3mNxWLx9PTcvHnzl19+yefz8\/PzlUplSEiIq6tra2sr0wjh73C5xSUo3HEOh6O1tfWPs3HuZopGo+FupnI3KcPCwjw9PSsqKoqKiohoeHhYrVZ7eXmJRKL6+vq9e\/deuXKltbXVZDKJxWKRSCSXy\/fu3Wu1WltaWux2+4IFCwICAnQ63e7du81mc2NjI5\/Pj4yM9Pb2Pn36dGFhITcb0mq1g4OD3MbQ0BA3nr6+vpaWFr1e\/+uvv\/J4vJ6enpqampiYmOPHjw8MDFw7cm7Y3L3bazU1NXl5eQUFBel0ug8\/\/PCuu+7y8PBQKpU9PT0zZszo6Ojo7e0dGBg4e\/bs0NCQWq2eM2dOWFiYXq\/fvXu30Wh0OBzj4+MajYa70UtE58+fNxgMJpOJx+M5OTlVVVW1tbUFBgZGRERYLJaioqLJVSGYAvjJUbipHTt2jI6O5uXlEdG6deueeuqpjIwMLm3wH4epCtyUSqV68cUXxWKxi4uLt7f3wYMHUQ3g4IoDAJjhrgoAMEM4AIAZwgEAzBAOAGCGcAAAM4QDAJghHADADOEAAGYIBwAwu80fOedtOHlnxwEA02Ji35Lb2AtXHADADOEAAGYIBwAwQzgAgBl+rR4AmOGKAwCYIRwAwAzhAABmCAcAMEM4AIAZwgEAzBAOAGCGcAAAM4QDAJghHADADOEAAGYIBwAwQzgAgBnCAQDMEA4AYIZwAAAzhAMAmCEcAMAM4QAAZggHADBDOACAGcIBAMwQDgBg9j+brmS4NYAx7wAAAABJRU5ErkJggg==","height":75,"width":360}}
%---
%[output:605acbef]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study_name","data_type","result","GroupCount"],"columns":4,"dataTypes":["string","cellstr","string","double"],"header":"1×4 table","name":"ans","rows":1,"type":"table","value":[["\"T1DEXI\"","'basal'","\"Invalid argument at position 1. ''tt'' must contain at least two samples to be resampled.\"","1"]]}}
%---
%[output:67065f61]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study_name","GroupCount","fun1_result"],"columns":3,"dataTypes":["string","double","double"],"header":"8×3 table","name":"ans","rows":8,"type":"table","value":[["\"T1DEXI\"","489","99.7955"],["\"DCLP3\"","112","100"],["\"DCLP5\"","100","100"],["\"Flair\"","115","100"],["\"IOBP2\"","343","100"],["\"Loop\"","845","100"],["\"PEDAP\"","99","100"],["\"T1DEXIP\"","239","100"]]}}
%---
%[output:87a5034c]
%   data: {"dataType":"tabular","outputData":{"columnNames":["study","patient","type","error"],"columns":4,"dataTypes":["string","string","char","string"],"header":"1×4 table","name":"errorExamples","rows":1,"type":"table","value":[["\"T1DEXI\"","\"775\"","basal","\"Invalid argument at position 1. ''tt'' must contain at least two samples to be resampled.\""]]}}
%---
%[output:08079044]
%   data: {"dataType":"textualVariable","outputData":{"name":"rawPath","value":"\"\/Users\/jan\/git\/nudgebg\/babelbetes\/data\/out\/2025-11-11 - improved basal\/study_name=T1DEXI\/data_type=basal\/patient_id=775\/610c38d5bf614d9896025b9819cb3205-0.parquet\""}}
%---
%[output:859bf8a7]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1\n"}}
%---
%[output:70d19842]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1\n"}}
%---
%[output:21a710e0]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"0"}}
%---
%[output:1477310d]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1\n"}}
%---
%[output:1ed35948]
%   data: {"dataType":"text","outputData":{"text":"\nans =\n\n  0×1 empty <a href=\"matlab:helpPopup('timetable')\" style=\"font-weight:bold\">timetable<\/a>\n\n    <strong>datetime<\/strong>    <strong>basal_rate<\/strong>\n    <strong>________<\/strong>    <strong>__________<\/strong>\n\n\n","truncated":false}}
%---
