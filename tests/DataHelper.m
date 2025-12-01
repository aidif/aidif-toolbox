classdef DataHelper
%DataHelper Utility for generating small, deterministic timetables used in tests
%
%   DataHelper provides static factory methods that return MATLAB
%   timetable objects populated with simple, repeatable data. These
%   helpers are intended for unit tests and examples where creating
%   compact CGM and insulin timetables is useful.
%
%   Example
%       cgmTT = DataHelper.getCGMTT();
%       insulinTT = DataHelper.getTotalInsulinTT();
%       mergedTT = DataHelper.getMergedTT();
%
%   See also: timetable
   
    properties (Constant)
        DefaultTimesToday = datetime("today") + minutes([0 5 10]);
        DefaultFlatEGV = [100 100 100];
        DefaultFlatInsulin = [1 1 1];
    end

    methods(Static)

        % Generate a CGM timetable for testing
        %
        % cgmTT = DataHelper.getCGMTT() returns a timetable with the
        %   default times and default EGV values [100 100 100].
        %
        % cgmTT = DataHelper.getCGMTT('Times', times, 'EGV', egv)
        %   allows overriding the Times and EGV
        %
        % Inputs (optional name-value pairs):
        %   'Times' - datetime vector of row times
        %   'EGV'   - numeric vector of glucose values
        %
        % Output:
        %   cgmTT - timetable with variable 'cgm'
        function cgmTT = getCGMTT(varargin)

            p = inputParser;
            addOptional(p, 'Times', DataHelper.DefaultTimesToday);
            addOptional(p, 'EGV', DataHelper.DefaultFlatEGV);
            parse(p, varargin{:});
        
            cgmTT = timetable( ...
                p.Results.Times', ...
                p.Results.EGV', ...
                'VariableNames',"cgm");
        end

        % Create a total insulin timetable for testing
        %
        % totalInsulinTT = DataHelper.getTotalInsulinTT()
        %   returns a timetable with default times and insulin values
        %   [1 1 1]. 
        %
        % totalInsulinTT = DataHelper.getTotalInsulinTT('Times', times, 'Insulin', insulin)
        %   allows overriding the Times and EGV
        %
        % Inputs (optional name-value pairs):
        %   'Times' - datetime vector of row times
        %   'Insulin' - numeric vector of total insulin values
        % 
        % Output:
        %   totalInsulinTT - timetable with variable 'totalInsulin'
        function totalInsulinTT = getTotalInsulinTT(varargin)

            p = inputParser;
            addOptional(p, 'Times', DataHelper.DefaultTimesToday);
            addOptional(p, 'Insulin', DataHelper.DefaultFlatInsulin);
            parse(p, varargin{:});
        
            totalInsulinTT = timetable( ...
                p.Results.Times', ...
                p.Results.Insulin', ...
                'VariableNames',"totalInsulin");
        end

        % Create a merged timetable containing both EGV and insulin
        %
        % mergedTT = DataHelper.getMergedTT()
        % returns a timetable with default times, egv and insulin values
        %
        % mergedTT = DataHelper.getMergedTT('Times', times, 'Insulin', insulin,'EGV', egv)
        %   allows overriding the Times, EGV and Insulin
        %
        % Output:
        %   mergedTT - timetable with variables ['egv', 'totalInsulin']
        function mergedTT = getMergedTT(varargin)

            p = inputParser;
            addOptional(p, 'Times', DataHelper.DefaultTimesToday);
            addOptional(p, 'Insulin', DataHelper.DefaultFlatInsulin);
            addOptional(p, 'EGV', DataHelper.DefaultFlatEGV);
            parse(p, varargin{:});
        
            mergedTT = timetable( ...
                p.Results.Times', ...
                p.Results.EGV', ...
                p.Results.Insulin', ...
                'VariableNames',["egv", "totalInsulin"]);
        end

    end
end