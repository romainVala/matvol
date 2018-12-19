function [ pool , cluster ] = ICM_start_cluster( NumWorkers )
% Start the parpool with ICM cluster, and setup the PATH env variable
% NumWorkers empty : use some (see defalut value)
% NumWorkers Inf : use all workers available
% NumWorkers x : use x workers
%
% See also ICM_set_pool ICM_set_path ICM_get_cluster


default_NumWorkers = 16;


%% Get cluster info

cluster= ICM_get_cluster(); % cluster info


%% Start parpool

if nargin < 1
    NumWorkers = default_NumWorkers; % just use some workers, not all
else
    if NumWorkers == Inf % use all
        NumWorkers = cluster.NumWorkers;
    end
end

pool = ICM_set_pool(NumWorkers);


%% Sub routines ?

% pass

fprintf('[%s]: done \n', mfilename)


end % function
