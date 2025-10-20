% processBabelbetes this script imports the babelbetes subject data streams
% (cgm, basal, and bolus insulin) and time aligns and interpolates the data
% to the requirements specified for RST#1
%
% The output of this script returns combined parquet files to the patient
% folders collecte in the data warehouse. The combined datasets can be used
% for further analysis.

%% create the import query table for babelbetes hive schema
rootFolder = "I:/Shared drives/AIDIF internal/03 Model Development/BabelBetes/babelbetes output/2025-09-23/";

[queryTable,dsClinic] = constructQueryTable(rootFolder);

% assign unique identifier based on subject, apply to all data types
[~,~,ic] = unique(queryTable(:,["study_name" "patient_id"]),...
                  "rows","stable");
queryTable{:,"unique_id"} = ic;
%% use the query table to specify only the data to import to workspace
subsetIndex = find(ismember(queryTable.study_name,["DCLP3","DCLP5"]));

%import data into tables by datatype
cgmTable = importByDataType(queryTable(subsetIndex,:),'cgm');
basalTable = importByDataType(queryTable(subsetIndex,:),'basal');
bolusTable = importByDataType(queryTable(subsetIndex,:),'bolus');
