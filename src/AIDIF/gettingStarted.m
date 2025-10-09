function gettingStarted()
    % GETTINGSTARTED Open the getting started guide for the toolbox
    %
    %   GETTINGSTARTED() opens the getting started guide for the toolbox.
    %
    %   Example:
    %       AIDIF.gettingStarted()
    %
    %   See also AIDIF.toolboxdir, AIDIF.toolboxversion

    % Display welcome message
    fprintf('Welcome to AIDIF Matlab Toolbox!\n\n');
    fprintf('A comprehensive set of validated models and tools to perform pre-clinical evaluation for AID systems and their components.\n\n');
    
    % Display version information
    fprintf('Version: %s\n', AIDIF.toolboxversion());
    
    % Display directory information
    fprintf('Toolbox directory: %s\n\n', AIDIF.toolboxdir());
    
    % Display available functions
    fprintf('Available functions:\n');
    fprintf('  - AIDIF.toolboxdir\n');
    fprintf('  - AIDIF.toolboxversion\n');
    fprintf('  - AIDIF.gettingStarted\n\n');
    
    % Display examples
    fprintf('Examples:\n');
    examplesDir = fullfile(AIDIF.toolboxdir(), 'code', 'examples');
    if exist(examplesDir, 'dir')
        exampleFiles = dir(fullfile(examplesDir, '*.m'));
        if ~isempty(exampleFiles)
            for i = 1:length(exampleFiles)
                fprintf('  - %s\n', exampleFiles(i).name);
            end
        else
            fprintf('  No examples found.\n');
        end
    else
        fprintf('  Examples directory not found.\n');
    end
    
    % Display documentation
    fprintf('\nDocumentation:\n');
    docsDir = fullfile(AIDIF.toolboxdir(), 'docs');
    if exist(docsDir, 'dir')
        fprintf('  Documentation is available in the docs directory:\n');
        fprintf('  %s\n', docsDir);
    else
        fprintf('  Documentation directory not found.\n');
    end
    
    fprintf('\nFor more information, see the README.md file in the toolbox directory.\n');
end
