addpath(genpath(pwd));
test_dir = "tests";
addpath(genpath(test_dir));

results = runtests(test_dir);

% Exit MATLAB with a status code indicating test success or failure
if any([results.Failed])
    exit(1); % Indicate failure
else
    exit(0); % Indicate success
end
