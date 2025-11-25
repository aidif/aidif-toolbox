disp("startup.m...")
disp("Adding paths.")
addpath(genpath(fullfile(pwd,'src')));
addpath(genpath(fullfile(pwd,'tests')));
addpath(genpath(fullfile(pwd,'tools')));
addpath(fullfile(pwd,'src','AIDIF','+AIDIF','python'));

disp("Setting up python environment...")
if ispc
    pythonPath = fullfile(pwd, '.venv', 'Scripts', 'python.exe');
else
    pythonPath = fullfile(pwd, '.venv', 'bin', 'python');
end

if exist(pythonPath, 'file')
    pyenv('Version', pythonPath)
else
    warning("Couldn't find python virtual environment, please install using `make install`")
end
