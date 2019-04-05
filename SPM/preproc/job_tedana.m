function [ job ] = job_tedana( meinfo, prefix, par )
%JOB_TEDANA
% This script is well discribeded with the comments, just read it
%
% See also


%% Check input arguments

narginchk(2,3)

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

% tedana.py arguments : script options
defpar.cmd_arg = ''; % Allows you to use all addition arguments not scripted in this job_tedana.m file
% defpar.subdir  = ''; % name of the working dir, if empty, write files in same dir as the echos

% matvol classic options
defpar.pct      = 0; % Parallel Computing Toolbox, will execute in parallel all the subjects
defpar.redo     = 0; % overwrite previous files
defpar.fake     = 0; % do everything exept running
defpar.verbose  = 2; % 0 : print nothing, 1 : print 2 first and 2 last messages, 2 : print all

% Cluster
defpar.sge      = 0; % for ICM cluster, run the jobs in paralle
defpar.jobname  = 'job_tedana';
defpar.walltime = '08:00:00'; % HH:MM:SS
defpar.mem      = 16000;      % MB

par = complet_struct(par,defpar);


%% Setup that allows this scipt to prepare the commands only, no execution

parsge  = par.sge;
par.sge = -1; % only prepare commands

parverbose  = par.verbose;
par.verbose = 0; % don't print anything yet


%% Expand meinfo path & TE

% pth
pth = [meinfo.path{:}];
pth = pth(:);
pth = cellfun(@char, pth, 'UniformOutput', 0);
pth = addprefixtofilenames(pth,prefix);
pth = cellfun(@cellstr, pth, 'UniformOutput', 0);

% TE
TE = [meinfo.TE{:}];
TE = TE(:);


%% Main

nJobs = length(pth);

job = cell(nJobs,1); % pre-allocation, this is the job containter

fprintf('\n')

skip  = [];
for iJob = 1 : nJobs
    
    % Extract subject name, and print it
    run_path = get_parent_path( pth{iJob}{1} );
    working_dir = run_path;
    
    % Already done processing ?
    if ~par.redo  &&  exist(fullfile(working_dir,'dn_ts_OC.nii'),'file') == 2
        fprintf('[%s]: skiping %d/%d @ %s because %s exist \n', mfilename, iJob, nJobs, run_path, 'dn_ts_OC.nii');
        jobchar = '';
        skip = [skip iJob];
    else
        % Echo in terminal & initialize job_subj
        fprintf('[%s]: Preparing JOB %d/%d for %s \n', mfilename, iJob, nJobs, run_path);
        jobchar = sprintf('#################### [%s] JOB %d/%d for %s #################### \n', mfilename, iJob, nJobs, run_path); % initialize
    end
    
    
    %-Prepare command : meica.py
    %==================================================================
    
    data_sprintf = repmat('%s ',[1  length(pth{iJob})]);
    data_sprintf(end) = [];
    data_arg = sprintf(data_sprintf,pth{iJob}{:}); % looks like : "path/to/echo1, path/to/echo2, path/to/echo3"
    
    echo_sprintf = repmat('%g ',[1 length(TE{iJob})]);
    echo_sprintf(end) = [];
    echo_arg = sprintf(echo_sprintf,TE{iJob}); % looks like : "TE1, TE2, TE3"
    
    % Main command
    cmd = sprintf('cd %s;\n tedana -e %s -d %s --maxit 5000',...
        working_dir, echo_arg, data_arg);
    
    % Other args ?
    if ~isempty(par.cmd_arg)
        cmd = sprintf('%s %s', cmd, par.cmd_arg);
    end
    
    % Finish preparing tedana job
    cmd = sprintf('%s \n',cmd);
    
    jobchar = [jobchar cmd]; %#ok<*AGROW>
    
    % Save job_subj
    job{iJob} = jobchar;
    
end % subj

% Now the jobs are prepared
job(skip) = [];


%% Run the jobs

% Fetch origial parameters, because all jobs are prepared
par.sge     = parsge;
par.verbose = parverbose;

% Run CPU, run !
job = do_cmd_sge(job, par);


end % function
