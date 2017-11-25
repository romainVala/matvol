function [ jobs ] = job_ending_rountines( jobs, skip, par )
% JOB_ENDING_ROUNTINES Wrapper to regroup some routnies at the end each
% job_* function form matvol
%   jobs : matlab batch job from SPM
%   skip : vector of jobs indexs to skip (can be empty [] )
%   par  : matvol classic parameters struct

%% Check input arguments

assert(nargin==3, 'All inputs are required : jobs, skip, par')
assert(iscell(jobs),'jobs must be cell')
assert(isnumeric(skip),'skip must be numeric')
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
    defpar.cmd_prepend = '';
    par = complet_struct(par,defpar);
    
    %     cmd{1} = sprintf('%s \n spm_jobman(''run'',j)',par.cmd_prepend);
    %     cmd = repmat(cmd,size(jobs));
    cmd=cell(size(jobs));
    tic
    for k=1:length(jobs)
        j=jobs{k};
         jstr = gencode(j);
         jstr{end+1} = sprintf('spm_jobman(''run'',j);\nclear j;\n');
         cmd{k}=jstr;
    end
    toc
    %    varfile = do_cmd_matlab_sge(cmd,par)
    do_cmd_matlab_sge(cmd,par)
    
%     for k=1:length(jobs)
%         j=jobs(k);
%         %cmd{1} = sprintf('%s \n spm_jobman(''run'',j)',par.cmd_prepend);
%         %varfile = do_cmd_matlab_sge(cmd,par);
%         save(varfile{k},'j');
%     end

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
