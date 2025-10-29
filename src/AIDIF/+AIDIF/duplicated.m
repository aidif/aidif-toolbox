function bDuplicated = duplicated(tt)
% DUPLICATED Identifies duplicated rows in a timetable.
%   bDup = duplicated(myTimetable); Checks for duplicates using all columns
%   bDup = duplicated(myTimetable(:, {'col1', 'col2'})); Check for duplicates only based on specified columns
%   bDup = duplicated(myTimetable(:, [])); Check for duplicates only based on row times (ignoring table data)

%   bDuplicated = DUPLICATED(tt)
%
%   Inputs:
%     tt - timetable to check for duplicated rows (using all columns)
%
%   Outputs:
%     bDuplicated - logical array indicating which rows have duplicate values
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
    bDuplicated = accumarray(ic,1)>1;
    bDuplicated = bDuplicated(ic);
end