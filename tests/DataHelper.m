classdef DataHelper
%DataHelper Utility for generating data for unit tests
   
    properties (Constant)
        DefaultTimesToday = datetime("today") + minutes([0 5 10]);
        DefaultFlatEGV = [100 100 100];
        DefaultFlatInsulin = [1 1 1];
        DefaultDataAssestDir = "assets";
        DefaultDataOutputDir = "outputs";
        TestStudyA = "StudyA";
        TestPatient1 = "Patient1";
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

        % Create a sample hive query table for testing
        % Input:
        %   testDir - directory under DefaultDataAssestDir containing test data files
        % Output:
        %   hiveQueryTable - table with columns ['path', 'data_type', 'study_name', 'patient_id']
        function hiveQueryTable = getHiveQueryTable(testDir, varargin)
           
            p = inputParser;
            addOptional(p, 'RootDir',  DataHelper.DefaultDataAssestDir);
            addOptional(p, 'CMGFile',  "cgm.parquet");
            addOptional(p, 'BasalFile', "basal.parquet");
            addOptional(p, 'BolusFile', "bolus.parquet");
            parse(p, varargin{:});

            fullPath = fullfile(pwd, p.Results.RootDir, testDir);

            if ~exist(fullPath, 'dir') == 7
                error(fprintf("%s testDir is invalid", fullPath));
            end

            paths = [ ...
                fullfile(fullPath, p.Results.CMGFile); ...
                fullfile(fullPath, p.Results.BasalFile); ...
                fullfile(fullPath, p.Results.BolusFile)];
            
            data_types = [ ...
                "cgm"; ...
                "basal"; ...
                "bolus"];
            
            study_names = [ ...
                DataHelper.TestStudyA; ...
                DataHelper.TestStudyA; ...
                DataHelper.TestStudyA];
            
            patient_ids = [ ...
                DataHelper.TestPatient1; ...
                DataHelper.TestPatient1; ...
                DataHelper.TestPatient1];
            
            hiveQueryTable = table(paths, data_types, study_names, patient_ids, ...
                'VariableNames', {'path', 'data_type', 'study_name', 'patient_id'});

        end

        % Get the full path for the combined output file
        % Input:
        %   outputDir - base output directory
        % Output:
        %   outputFilePath - full path to the combined output file
        function outputFilePath = getCombinedOutputFullPath(outputDir)
            outputFilePath = fullfile(outputDir, ...
                "study_name=" + DataHelper.TestStudyA, ...
                "data_type=combined", ...
                "patient_id="+DataHelper.TestPatient1, ...
                "babelbetes_combined.parquet");
        end
    end
end
