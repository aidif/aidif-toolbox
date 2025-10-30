function isDuplicated = findDuplicates(tt)
% findDuplicates Identifies duplicated rows in a timetable.
%   isDuplicated = findDuplicates(myTimetable); Checks for duplicates using all columns
%   isDuplicated = findDuplicates(myTimetable(:, {'col1', 'col2'})); Check for duplicates only based on specified columns
%   isDuplicated = findDuplicates(myTimetable(:, [])); Check for duplicates only based on row times (ignoring table data)
%
%   Inputs:
%     tt - timetable to check for duplicated rows (using all columns)
%
%   Outputs:
%     isDuplicated - logical array indicating which rows have duplicate values
%                   (true for all rows that share identical values with other rows)
%

%   Author: Jan Wrede
%   Date: 2025-10-29
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) 2025, AIDIF
%   All rights reserved

    [~,~,ic] =  unique(tt);
    isDuplicated = accumarray(ic,1)>1;
    isDuplicated = isDuplicated(ic);
end
