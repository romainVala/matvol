function ICM_set_path()
% Use this function at the buigining for your script, BEFORE the PARFOR loop
%
% See also ICM_start_cluster

global ICM_PATH ICM_POOL

assert(~isempty(ICM_PATH), 'Use ICM_set_pool() first');
assert(~isempty(ICM_POOL), 'Use ICM_set_pool() first');

icm_path = ICM_PATH; % necessary to make a copy of the variable

fprintf('[%s]: Setting PATH env for the workers ... \n', mfilename)
parfor iWorker = 1 : ICM_POOL.NumWorkers
    setenv('PATH',icm_path); % send "client" PATH env to the workers
end
fprintf('[%s]: ... done \n', mfilename)

end % function
