% Add necessary path
addpath(genpath(fullfile(matlabroot,'examples','driving'))); % Automated Driving Toolbox is required!
addpath(fullfile('src', 'main'));                            % src path

% Load and simulate system
load_system('AEBTestBenchExample_ByMatlab');
sim('AEBTestBenchExample_ByMatlab');
