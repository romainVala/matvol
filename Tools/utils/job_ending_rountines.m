function [ jobs ] = job_ending_rountines( jobs, skip, par )
% JOB_ENDING_ROUNTINES Wrapper to regroup some routnies at the end each
% job_* function form matvol
%   jobs : matlab batch job from SPM
%   skip : vector of jobs indexs to skip (can be empty [] )
%   par  : matvol classic parameters struct

%% Check input arguments

assert(nargin==3, 'All inputs are required : jobs, skip, par')
assert(isstruct(jobs),'jobs must be struct')
assert(isvector(skip)&&isnumeric(skip),'skip must be numeric vector')
assert(isstruct(par),'par must be struct')


%% Routines

% Skip the empty jobs
jobs(skip) = [];

% Jobs are remaining ?
if isempty(jobs)
    return
end

% SGE
if par.sge
    for vol=1:length(jobs)
        j       = jobs(vol); %#ok<NASGU>
        cmd     = {'spm_jobman(''run'',j)'};
        varfile = do_cmd_matlab_sge(cmd,par);
        save(varfile{1},'j');
    end
end

% Display
if par.display
    spm_jobman('interactive',jobs);
    spm('show');
end

% Run !
if par.run
    spm_jobman('run',jobs)
end

end % function
