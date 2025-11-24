%[text] ## Use Python to read pyarrow data from parquet files
%[text] This notebook illustrates how we use python to read timedelta column units from parquet files arrow schema which is not understood by matlab (probably because 
%[text] ### Make sure to initialize a python environmentment:
%[text] cd \<aidiftoolbox\>
%[text] python -m venv ./venv
%[text] source ./venv/bin/activate
%[text] pip install -r src/AIDIF/+AIDIF/python/requirements.txt
%[text] ### Connect Matlab and python
%[text] Point matlab to the python of the virtual environment we just created
pyenv('Version',fullfile(pwd,'venv','bin','python')) %[output:6307bf38]
%[text] ### Create a pandas dataframe and save to parquet
code = [
"from datetime import datetime, timedelta" newline ...
"import pandas as pd" newline ...
"now = datetime.now()" newline ...
"df = pd.DataFrame({" newline ...
"    'datetime': [now + timedelta(hours=i) for i in range(1, 4)]," newline ...
"    'bolus': [1.2, 2, 3]," newline ...
"    'delivery_duration': [" newline ...
"        pd.Timedelta(seconds=1)," newline ...
"        pd.Timedelta(minutes=2)," newline ...
"        pd.Timedelta(hours=3)" newline ...
"    ]" newline ...
"})" newline ...
"df.to_parquet('python.parquet')" ...
];

pyrun(code);
%[text] ### Reading it with Matlab
tt = parquetread('python.parquet') %[output:2b81f659]
parquetinfo('python.parquet') %[output:9144eb4c]
%[text] As we dan see, Matlab does not convert delivery duration to the correct unit. That's because it treats it as int64, not as a duration.
%[text] ### Read the full parquet arrow information (using python)
file_path = "python.parquet";

code = [
"import pyarrow.parquet as pq" newline ...
"schema_arrow = pq.ParquetFile('" + file_path + "').schema_arrow" newline 
];
arrowSchema = pyrun(code,'schema_arrow');
disp(arrowSchema) %[output:049d0e68]
unit = string(arrowSchema.field('delivery_duration').type.unit);
fprintf("The delivery_duration unit is %s\n", string(unit)); %[output:7c1c1fe3]
%[text] ### Or by calling our python script
arrowSchema = pyrunfile('readParquetArrowSchema.py','schema',path = 'python.parquet');
unit = string(arrowSchema.field('delivery_duration').type.unit);
fprintf("The delivery_duration unit is %s\n", string(unit)); %[output:5cddb43a]
%[text] ### Now convert the duration
switch unit
    case "ns"
        base = 1e6;
    case "ms"
        base = 1e3;
    otherwise
        error("Unit not expected");
end
delivery_duration = milliseconds(tt.delivery_duration/base);
display(tt) %[output:55ee05d3]
%%
%[text] ### Or by calling our convenience function
base =  AIDIF.readParquetDurationBase('python.parquet','delivery_duration');
fprintf("Base = %d",base) %[output:20c85e67]
delivery_duration = milliseconds(tt.delivery_duration/base);
disp(delivery_duration) %[output:3691a4fe]
%[text] ### 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:6307bf38]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  <a href=\"matlab:helpPopup('matlab.pyclient.PythonEnvironment')\" style=\"font-weight:bold\">PythonEnvironment<\/a> with properties:\n\n          Version: \"3.11\"\n       Executable: \"\/Users\/jan\/git\/aidif\/aidif-toolbox\/venv\/bin\/python\"\n          Library: \"\/Users\/jan\/.pyenv\/versions\/3.11.0\/lib\/libpython3.11.dylib\"\n             Home: \"\/Users\/jan\/git\/aidif\/aidif-toolbox\/venv\"\n           Status: Loaded\n    ExecutionMode: InProcess\n        ProcessID: \"59632\"\n      ProcessName: \"MATLAB\"\n"}}
%---
%[output:2b81f659]
%   data: {"dataType":"tabular","outputData":{"columnNames":["datetime","bolus","delivery_duration"],"columns":3,"dataTypes":["datetime","double","int64"],"header":"3×3 table","name":"tt","rows":3,"type":"table","value":[["24-Nov-2025 17:18:34","1.2000","1000000000"],["24-Nov-2025 18:18:34","2","120000000000"],["24-Nov-2025 19:18:34","3","10800000000000"]]}}
%---
%[output:9144eb4c]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  <a href=\"matlab:helpPopup('matlab.io.parquet.ParquetInfo')\" style=\"font-weight:bold\">ParquetInfo<\/a> with properties:\n\n               Filename: \"\/Users\/jan\/git\/aidif\/aidif-toolbox\/python.parquet\"\n               FileSize: 2870\n           NumRowGroups: 1\n        RowGroupHeights: 3\n          VariableNames: [\"datetime\"    \"bolus\"    \"delivery_duration\"]\n          VariableTypes: [\"datetime\"    \"double\"    \"int64\"]\n    VariableCompression: [\"snappy\"    \"snappy\"    \"snappy\"]\n       VariableEncoding: [\"dictionary\"    \"dictionary\"    \"dictionary\"]\n                Version: \"2.0\"\n"}}
%---
%[output:049d0e68]
%   data: {"dataType":"text","outputData":{"text":"  Python <a href=\"matlab:helpPopup('py.pyarrow.lib.Schema')\" style=\"font-weight:bold\">Schema<\/a> with properties:\n\n           metadata: [1×1 py.dict]\n              names: [1×3 py.list]\n    pandas_metadata: [1×1 py.dict]\n              types: [1×3 py.list]\n\n    datetime: timestamp[ns]\n    bolus: double\n    delivery_duration: duration[ns]\n    -- schema metadata --\n    pandas: '{\"index_columns\": [{\"kind\": \"range\", \"name\": null, \"start\": 0, \"' + 637\n\n","truncated":false}}
%---
%[output:7c1c1fe3]
%   data: {"dataType":"text","outputData":{"text":"The delivery_duration unit is ns\n","truncated":false}}
%---
%[output:5cddb43a]
%   data: {"dataType":"text","outputData":{"text":"The delivery_duration unit is ns\n","truncated":false}}
%---
%[output:55ee05d3]
%   data: {"dataType":"tabular","outputData":{"columnNames":["datetime","bolus","delivery_duration"],"columns":3,"dataTypes":["datetime","double","int64"],"header":"3×3 table","name":"tt","rows":3,"type":"table","value":[["24-Nov-2025 17:18:34","1.2000","1000000000"],["24-Nov-2025 18:18:34","2","120000000000"],["24-Nov-2025 19:18:34","3","10800000000000"]]}}
%---
%[output:20c85e67]
%   data: {"dataType":"text","outputData":{"text":"Base = 1000000","truncated":false}}
%---
%[output:3691a4fe]
%   data: {"dataType":"text","outputData":{"text":"       1 sec\n     120 sec\n   10800 sec\n\n","truncated":false}}
%---
