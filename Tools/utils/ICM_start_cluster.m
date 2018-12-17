function [ pool , cluster ] = ICM_start_cluster( NumWorkers )
% Start the parpool with ICM cluster, and setup the PATH env variable
% NumWorkers empty : use some (see defalut value)
% NumWorkers Inf : use all workers available
% NumWorkers x : use x workers
%
% See also ICM_set_pool ICM_set_path ICM_get_cluster


default_NumWorkers = 16;


%% Get cluster info

cluster = parcluster('ICM_cluster');


%% Start parpool

if nargin < 1
    pool = ICM_set_pool(default_NumWorkers); % just use some workers, not all
else
    if NumWorkers == Inf % use all
        NumWorkers = cluster.NumWorkers;
    end
    pool = ICM_set_pool(NumWorkers);
end


%% Set PATH env for the workers

ICM_set_path();

fprintf('[%s]: done \n', mfilename)


end % function
