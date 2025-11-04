
rootFolder = "/Users/jan/git/aidif/out";
queryTable = AIDIF.constructHiveQueryTable(rootFolder);
%%\ 

study = 'DCLP3'
patient = '59'
type = 'basal'
rawPath = queryTable(queryTable.study_name == study & ...
                  queryTable.patient_id == patient & ...
                  queryTable.data_type == type ,:).path

raw = parquetread(rawPath, "OutputType", "timetable");

%%\

bTimeDup = AIDIF.findDuplicates(raw(:,[]))
sum(bTimeDup)

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
