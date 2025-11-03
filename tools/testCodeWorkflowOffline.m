%[text] This script performs the code testing using matbox. The logic is identical to the github workflow but changes so it runs locally. 
%   Author: Jan Wrede
%   Date: 2025-10-22
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) year, AIDIF
%   All rights reserved

%[text] 
src_dir = "src";
test_dir = "tests";
addpath(genpath(src_dir));
addpath(genpath(test_dir));

%[text] Load all files from src folder
files = dir(fullfile(src_dir, '**', '*.m'));
disp("All file candidates for testing:") %[output:755fcf56]
disp(string({files.name})') %[output:597157df]
%[text] Remove files to be excluded
%load excluded file names
ignoreFile = 'codecov.ignore';
exclude = string([]);
if exist(ignoreFile, 'file')
  fid = fopen(ignoreFile, 'r');
  if fid ~= -1
      line = fgetl(fid);
      while ischar(line)
          filename = strtrim(line);
          % Skip empty lines and comments
          if ~isempty(line) && ~startsWith(filename, '#')
              exclude(end+1) = filename;
          end
          line = fgetl(fid);
      end
      fclose(fid);
  end
end
disp("Files to be excluded:") %[output:2c63607c]
disp(exclude') %[output:099588cc]

% Remove excluded files
if ~isempty(exclude)
    files = files(~ismember(string({files.name}), exclude));
end
disp("Remaining files to be tested:") %[output:157da9e6]
disp(string({files.name})') %[output:43a305fa]
filePaths = string(fullfile({files.folder}, {files.name}));
%[text] Run matbox to perform tests
%run matbox
matbox.tasks.testToolbox(pwd, ... %[output:group:90084b74] %[output:03f0168c]
    'SourceFolderName', src_dir, ... %[output:03f0168c]
    'TestsFolderName', test_dir, ... %[output:03f0168c]
    'ReportSubdirectory', '', ... %[output:03f0168c]
    'CreateBadge', true, ... %[output:03f0168c]
    'CoverageFileList', filePaths, ... %[output:03f0168c]
    HtmlReports=true); %[output:group:90084b74] %[output:03f0168c]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":50.6}
%---
%[output:755fcf56]
%   data: {"dataType":"text","outputData":{"text":"All file candidates for testing:\n","truncated":false}}
%---
%[output:597157df]
%   data: {"dataType":"text","outputData":{"text":"    \"Contents.m\"\n    \"gettingStarted.m\"\n    \"processBabelbetes.m\"\n    \"constructHiveQueryTable.m\"\n    \"duplicated.m\"\n    \"findGaps.m\"\n    \"interpolateBasal.m\"\n    \"interpolateBolus.m\"\n    \"roundTo5Minutes.m\"\n    \"toolboxdir.m\"\n    \"toolboxversion.m\"\n    \"findingBasalGaps.m\"\n    \"resamplingBasalRates.m\"\n    \"resamplingBoluses.m\"\n\n","truncated":false}}
%---
%[output:2c63607c]
%   data: {"dataType":"text","outputData":{"text":"Files to be excluded:\n","truncated":false}}
%---
%[output:099588cc]
%   data: {"dataType":"text","outputData":{"text":"    \"Contents.m\"\n    \"gettingStarted.m\"\n    \"processBabelbetes.m\"\n    \"resamplingBasalRates.m\"\n    \"findingBasalGaps.m\"\n    \"resamplingBoluses.m\"\n\n","truncated":false}}
%---
%[output:157da9e6]
%   data: {"dataType":"text","outputData":{"text":"Remaining files to be tested:\n","truncated":false}}
%---
%[output:43a305fa]
%   data: {"dataType":"text","outputData":{"text":"    \"constructHiveQueryTable.m\"\n    \"duplicated.m\"\n    \"findGaps.m\"\n    \"interpolateBasal.m\"\n    \"interpolateBolus.m\"\n    \"roundTo5Minutes.m\"\n    \"toolboxdir.m\"\n    \"toolboxversion.m\"\n\n","truncated":false}}
%---
%[output:03f0168c]
%   data: {"dataType":"text","outputData":{"text":".......... .......... .......... .........\nMATLAB code coverage report has been saved to:\n <a href=\"matlab:web('https:\/\/127.0.0.1:31517\/static\/lRwR6cfA\/report05f59e52-8f52-4cad-b52a-1da0f2cc895d\/codecoverage.html?snc=ZY73KF&Filterable=true','-noaddressbox','-new')\">\/Users\/jan\/git\/aidif\/aidif-toolbox\/docs\/reports\/codecoverage.html<\/a>\nGenerating test report. Please wait.\n    Preparing content for the test report.\n    Adding content to the test report.\n    Writing test report to file.\nTest report has been saved to:\n <a href=\"matlab:web('\/Users\/jan\/git\/aidif\/aidif-toolbox\/docs\/reports\/testreport.html','-new')\">\/Users\/jan\/git\/aidif\/aidif-toolbox\/docs\/reports\/testreport.html<\/a>\nSaved badge to \/Users\/jan\/git\/aidif\/aidif-toolbox\/.github\/badges\/tests.svg\nTest result summary:\n   39 Passed, 0 Failed, 0 Incomplete.\n   1.2444 seconds testing time.\n","truncated":false}}
%---
