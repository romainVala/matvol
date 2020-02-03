function [ job, fmask ] = do_fsl_robust_mask_epi( fin, par, jobappend )
% DO_FSL_ROBUST_MASK_EPI will use fslmath to compute a temporal mean, then BET to generate a mask
% This strategy WORKS with signal BIAS in the volume
%
% Seel also do_fsl_mean do_fsl_bet

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - fin is required',mfilename)
end


%% Check input arguments

if ~exist('fin'      ,'var'), fin       = get_subdir_regex_files; end
if ~exist('par'      ,'var'), par       = ''; end
if ~exist('jobappend','var'), jobappend = ''; end

obj = 0;
if isa(fin,'volume')
    obj      = 1;
    img_obj  = fin.removeEmpty; % .removeEmpty strips dimensions and remove empty objects
    fin      = img_obj.toJob;   % .toJob converts to cellstr
end

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
defpar.mem               = '2G';

defpar.skip              = 1;
defpar.redo              = 0;
defpar.verbose           = 1;
defpar.auto_add_obj      = 1;

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

FMEAN = cell(nFile,1);
FMASK = cell(nFile,1);
FBET  = cell(nFile,1);

for iFile = 1 : nFile
    
    [pathstr, name, ~] = fileparts(fin{iFile});
    
    [ fTmean, job_Tmean ] = do_fsl_mean( fin{iFile}, [par.meanprefix name], par);
    
    par.output_name = [par.betprefix fTmean];
    [~, par.output_name, ~] = fileparts(par.output_name); % remove extension (1/2)
    [~, par.output_name, ~] = fileparts(par.output_name); % remove extension (2/2)
    
    [ job_bet , fmask ] = do_fsl_bet ( fullfile( pathstr, fTmean), par );
    fmask = char(fmask);
    
    fbet = addprefixtofilenames(fullfile( pathstr, fTmean),par.betprefix);
    if par.skip && exist(fmask,'file')
        fprintf('skipping fsl_robust_mask_epi because %s exists \n',fmask)
        skip = [skip iFile]; %#ok<AGROW>
    else
        job{iFile} = sprintf('%s\n%s',char(job_Tmean),char(job_bet));
    end
    
    % remove extension
    fTmean = char(fTmean  );
    fmask  = char(fmask       );
    fbet   = char(fbet);
    [~, fTmean, ~] = fileparts(fTmean);
    [~, fTmean, ~] = fileparts(fTmean);
    [~, fmask , ~] = fileparts(fmask );
    [~, fmask , ~] = fileparts(fmask );
    [~, fbet  , ~] = fileparts(fbet );
    [~, fbet  , ~] = fileparts(fbet );
    
    % save
    FMEAN{iFile} = fTmean;
    FMASK{iFile} = fmask;
    FBET {iFile} = fbet;
    
end

job(skip) = [];


%% Run the jobs

% Fetch origial parameters, because all jobs are prepared
par.sge     = parsge;
par.verbose = parverbose;

% Run CPU, run !
job = do_cmd_sge(job, par, jobappend);


%% Add outputs objects

if obj && par.auto_add_obj && (par.run || par.sge)
    
    tags = {img_obj.tag}';
    
    switch par.fsl_output_format
        case 'NIFTI_GZ'
            ext = '.nii.gz';
        case 'NIFTI'
            ext = '.nii';
        otherwise
            error ('extension not coded')
    end
    
    for iVol = 1 : length(img_obj)
        
        % Shortcut
        vol = img_obj(iVol);
        ser = vol.serie;
        
        if par.run     % use the normal method
            ser.addVolume( ['^' FMEAN{iVol} '.nii'] , [              par.meanprefix tags{iVol}        ], 1 );
            ser.addVolume( ['^'  FBET{iVol} '.nii'] , [par.betprefix par.meanprefix tags{iVol}        ], 1 );
            ser.addVolume( ['^' FMASK{iVol} '.nii'] , [par.betprefix par.meanprefix tags{iVol} '_mask'], 1 );
        elseif par.sge % add the new volume in the object manually, because the file is not created yet
            ser.volume(end + 1) = volume( fullfile(ser.path,[FMEAN{iVol} ext])  , [              par.meanprefix tags{iVol}        ], ser.exam, ser );
            ser.volume(end + 1) = volume( fullfile(ser.path,[ FBET{iVol} ext])  , [par.betprefix par.meanprefix tags{iVol}        ], ser.exam, ser );
            ser.volume(end + 1) = volume( fullfile(ser.path,[FMASK{iVol} ext])  , [par.betprefix par.meanprefix tags{iVol} '_mask'], ser.exam, ser );
        end
        
    end
    
end


end % function
