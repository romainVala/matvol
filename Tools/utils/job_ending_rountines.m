function [ jobs ] = job_ending_rountines( jobs, skip, par )
% JOB_ENDING_ROUNTINES Wrapper to regroup some routnies at the end each
% job_* function form matvol
%   jobs : matlab batch job from SPM
%   skip : vector of jobs indexs to skip (can be empty [] )
%   par  : matvol classic parameters struct

%% Check input arguments

assert(nargin==3, 'All inputs are required : jobs, skip, par')
assert(iscell(jobs), 'jobs must be cell')
assert(isnumeric(skip), 'skip must be numeric')
assert(isstruct(par), 'par must be struct')


%% defpar

defpar.sge      = 0;
defpar.run      = 0;
defpar.display  = 0;
defpar.pct      = 0; % Parallel Computing Toolbox
defpar.concat = 1;

par = complet_struct(par,defpar);


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
    
    cmd=cell(length(jobs)/par.concat,1);
    tic
    nb_job=0;
    for k=1:par.concat:length(jobs)
        nb_job=nb_job+1;
        jstr={};
        for kk=1:par.concat
            j=jobs{k+kk-1};
            jstr = [jstr gencode(j)];
            if isfield(par,'cmd_prepend')
                jstr{end+1} = sprintf('%s\n spm_jobman(''run'',{j});\nclear j;\n',par.cmd_prepend);
            else
                jstr{end+1} = sprintf('spm_jobman(''run'',{j});\nclear j;\n');
            end
        end
        cmd{nb_job}=jstr;
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
    if par.pct % Parallel Computing Toolbox
        parfor j = 1 : numel(jobs)
            spm_jobman('run',jobs(j))
        end % parfor
    else
        spm_jobman('run',jobs)
    end
end


end % function
