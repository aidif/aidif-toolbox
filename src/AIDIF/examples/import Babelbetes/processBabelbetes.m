% processBabelbetes this script imports the babelbetes subject data streams
% (cgm, basal, and bolus insulin) and time aligns and interpolates the data
% to the requirements specified for RST#1
%
% The output of this script returns combined parquet files to the patient
% folders collecte in the data warehouse. The combined datasets can be used
% for further analysis.

%% create the import query table for babelbetes hive schema
rootFolder = "/Users/jan/git/aidif/out";

hive_table = constructQueryTable(rootFolder);

%%
subset = queryTable(hive_table .study_name == 'DCLP3' & hive_table .patient_id=='111',:);
pqStore = parquetDatastore(subset.filePaths);
pqStore.read()

