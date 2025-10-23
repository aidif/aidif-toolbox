function [outputArg1,outputArg2] = aidifFunctionTemplate(inputArg1,inputArg2,nameValueArgs)
%AIDIFFUNCTIONTEMPLATE function template for use in the AIDIF toolbox.
%   Copy this function when making a new function and fill in. Some style
%       specifics are to indent after the first line of any description. 
%       add extra lines only between sections of the code header, and keep
%       documentaion about author, licensing, and copyright separate from
%       the header block.
%
%   SYNTAX:
%   [outputArg1] = aidifFunctionTemplate(inputArg1) describe function
%       output when certain arguments or data types are passed.
%   [outputArg1] = aidifFunctionTemplate(inputArg1,inputArg2) describe the
%       function output under different arguments and data types.
%
%   INPUTS:
%   inputArg1: description of inputArg1 argument. If the descsription goes
%       beyond 1 line, indent the following lines
%   inputArg2: description of inputArg2 argument.
%
%   OUTPUTS: 
%   outputArg1: description of outputArg1 argument. If the descsription 
%       goes beyond line 1, indent the following lines.
%   outputArg2: description of outputArg2 argument.
%
%   NAME-VALUE PAIR ARGUMENTS (Optional)
%   name1 - description of name-value argument for name1
%   name2 - description of name-value argument for name2
%
%   EXAMPLES:
%   Add example uses of function syntax, complete with any example data
%       needed.
%
%   See also relevantFunction1, relevantFunction2

%   Author: Name
%   Date: date
%   
%   This file is part of the larger AIDIF-toolbox project and is licensed 
%       under the MIT license. A copy of the MIT License can be found in 
%       the project's root directory.
%
%   Copyright (c) year, AIDIF
%   All rights reserved

arguments (Input)
    inputArg1 (1,1) double {mustBePositive}
    inputArg2 timetable {mustBeNonempty}
    nameValueArgs.name = 'default'
    nameValueArgs.offset = 0
end

arguments (Output)
    outputArg1
    outputArg2
end

outputArg1 = inputArg1;
outputArg2 = inputArg2;
end
