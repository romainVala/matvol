function pool = ICM_set_pool(NumWorkers)
% Call thus function to start the parallel pool of worker
% IMPORTANT : Use ICM_set_path at the beguining of yout script
%
% See also ICM_start_cluster

clear global ICM_PATH ICM_POOL % reset
global ICM_PATH ICM_POOL

%% Get cluster info

cluster= ICM_get_cluster(); % cluster info


%% Start parpool

if nargin < 1
    NumWorkers = cluster.NumWorkers;
end

pool = gcp('nocreate'); % If no pool, do not create new one.
if isempty(pool)
    fprintf('[%s]: NumWorkers = %d \n', mfilename, NumWorkers)
    pool = parpool(cluster,NumWorkers);
end
fprintf('[%s]: parpool using "ICM_cluster" starded with %d workers \n', mfilename, NumWorkers)


%% Outputs

ICM_POOL = pool;
ICM_PATH = getenv('PATH'); % store PATH env from the "client"


end % function
