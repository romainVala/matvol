function [ job, fmask ] = do_fsl_robust_mask_epi( fin, par, jobappend )
% DO_FSL_ROBUST_MASK_EPI will use fslmath to compute a temporal mean, then BET to generate a mask


%% Check input arguments

if ~exist('fin'      ,'var'), fin       = get_subdir_regex_files; end
if ~exist('par'      ,'var'), par       = ''; end
if ~exist('jobappend','var'), jobappend = ''; end

% I/O
defpar.meanprefix        = 'Tmean_';
defpar. betprefix        =   'bet_';
defpar.fsl_output_format = 'NIFTI_GZ'; % ANALYZE, NIFTI, NIFTI_PAIR, NIFTI_GZ

% bet options
defpar.robust           = 1;     % robust brain centre estimation (iterates BET several times)
defpar.mask             = 1;     % generate binary brain mask
defpar.frac             = 0.3 ;  % fractional intensity threshold (0->1); default=0.5; smaller values give larger brain outline estimates

% fsl options
defpar.software         = 'fsl'; % to set the path
defpar.software_version = 5;     % 4 or 5 : fsl version

defpar.sge               = 0;
defpar.jobname           = 'fsl_robust_mask_epi';
defpar.skip              = 1;
defpar.redo              = 0;
defpar.verbose           = 1;

par = complet_struct(par,defpar);

% retrocompatibility
if par.redo
    par.skip = 0;
end


%% Setup that allows this scipt to prepare the commands only, no execution

parsge  = par.sge;
par.sge = -1; % only prepare commands

parverbose  = par.verbose;
par.verbose = 0; % don't print anything yet


%% main

fin   = cellstr(char(fin)); % make sure the input is a single-level cellstr
nFile = length (     fin );

job   = cell(nFile,1);
fmask = cell(nFile,1);
skip = [];
for iFile = 1 : nFile
    
    [pathstr, name, ~] = fileparts(fin{iFile});
    
    [ file_Tmean, job_Tmean ] = do_fsl_mean( fin{iFile}, [par.meanprefix name], par);
    
    par.output_name = [par.betprefix file_Tmean];
    [~, par.output_name, ~] = fileparts(par.output_name); % remove extension (1/2)
    [~, par.output_name, ~] = fileparts(par.output_name); % remove extension (2/2)
    
    [ job_bet   , fmask     ] = do_fsl_bet ( fullfile( pathstr, file_Tmean), par );
    
    final_output = addprefixtofilenames(fullfile( pathstr, file_Tmean),par.betprefix);
    final_output = addsuffixtofilenames(final_output,'_mask');
    if par.skip && exist(final_output,'file')
        fprintf('skipping fsl_robust_mask_epi because %s exists \n',final_output)
        skip = [skip iFile]; %#ok<AGROW>
    else
        job{iFile} = sprintf('%s\n%s',char(job_Tmean),char(job_bet));
    end
    
end

job(skip) = [];


%% Run the jobs

% Fetch origial parameters, because all jobs are prepared
par.sge     = parsge;
par.verbose = parverbose;

% Run CPU, run !
job = do_cmd_sge(job, par, jobappend);


end % function
