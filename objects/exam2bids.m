function [ job ] = exam2bids( examArray , bidsDir , par )
%EXAM2BIDS transform an array of @exam objects into BIDS architecture
%
% Syntax : [ job ] = exam2bids( examArray , bidsDir , par )
%
%
% See also exam
%

% In this code, variables in CAPITAL letters are objects : EXAM, ANAT_serie, ANAT_volume, ...

if nargin == 0
    help(mfilename)
    return
end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

assert( isa( examArray, 'exam' ), 'examArray must be a @exam object array' )
assert( ischar(bidsDir)         , 'bidsDir must be a char'                 )


%% defpar

% BIDS architecture :

% anat
defpar.regextag_anat_serie  = 'anat';
defpar.regextag_anat_volume = '^s';
defpar.regextag_anat_json   = '.*';

% func
defpar.regextag_func_serie  = 'func';
defpar.regextag_func_volume = '^f';
defpar.regextag_func_json   = '.*';

% dwi
defpar.regextag_dwi_serie   = 'dwi';
defpar.regextag_dwi_volume  = '^f';
defpar.regextag_dwi_json    = '.*';

% fmap
defpar.regextag_fmap_serie   = 'fmap';
defpar.regextag_fmap_volume  = '^s';
defpar.regextag_fmap_json    = '.*';

% Other options :
defpar.copytype = 'link'; % can be 'link' or 'copy'

%--------------------------------------------------------------------------

defpar.sge      = 0;
defpar.jobname  = 'matvol_exam2bids';
defpar.walltime = '00:30:00';
defpar.pct      = 0;

defpar.redo     = 0;
defpar.run      = 1;
defpar.display  = 0;
defpar.verbose  = 2;

par = complet_struct(par,defpar);


%% Prepare all commands

if par.verbose > 0
    fprintf('\n')
end

nrExam = numel(examArray);
job = cell(nrExam,1); % pre-allocation, this is the job containter

[success,message] = mkdir(bidsDir);
if ~success
    error('%s : bidsDir', message)
end


%% .bidsignore
% For BIDS Validator @ https://incf.github.io/bids-validator/ , ignore some non-official patterns

bidsignore = {
    '*boldphase*'
    '*inv-1*'
    '*inv-2*'
    '*T1map*'
    };

fileID = fopen( fullfile(bidsDir,'.bidsignore') , 'w' , 'n' , 'UTF-8' );
if fileID < 0
    warning('[%s]: Could not open %s', mfilename, filename)
end
fprintf(fileID,'%s\n',bidsignore{:});
fclose(fileID);


%% ########################################################################
% dataset_description.json

% Name
study_path = examArray(1).path;
if strcmp(study_path(end),filesep) % remove '/' at the end, if exists
    study_path = study_path(1:end-1);
end
study_path = fileparts(study_path);
dataset_description.Name = study_path; % dir of the study, such as /export/dataCENIR/dicom/nifti_raw/PRISMA_CENIR_DEV

% BIDSVersion
dataset_description.BIDSVersion = '1.1.1';

% License
dataset_description.License = 'PDDL';

% Authors
dataset_description.Authors = {'CENIR-ICM', 'Romain Valabregue', 'Benoit Beranger'};

% Acknowledgements
dataset_description.Acknowledgements = '';

% HowToAcknowledge
dataset_description.HowToAcknowledge = '';

% Funding
dataset_description.Funding = {''};

% ReferencesAndLinks
dataset_description.ReferencesAndLinks = {'https://github.com/romainVala/matvol'};

% DatasetDOI
dataset_description.DatasetDOI = '';

json_dataset_description = struct2jsonSTR( dataset_description );
job_header = sprintf('## dataset_description.json ## \n');
job_header = jobcmd_write_json_bids( job_header, json_dataset_description, fullfile(bidsDir,'dataset_description.json') );


%% Main loop

for e = 1:nrExam
    %% ####################################################################
    % Initialization
    
    EXAM = examArray(e); % shortcut (E is a pointer, not a copy of the object)
    
    % Echo in terminal & initialize job_subj
    if par.verbose > 0
        fprintf('[%s]: Preparing JOB %d/%d for %s \n', mfilename, e, nrExam, EXAM.path);
    end
    job_subj = sprintf('#################### [%s] JOB %d/%d for %s #################### \n\n', mfilename, e, nrExam, EXAM.path); % initialize
    %#ok<*AGROW>
    
    
    %% ####################################################################
    % sub DIR
    
    sub_name = sprintf('sub-%s',del_(EXAM.name));
    sub_path = fullfile( bidsDir, sub_name );
    job_subj = [ job_subj sprintf('mkdir -p %s \n\n', sub_path) ];
    
    
    %% ####################################################################
    % ses-Sx DIR
    
    ses_name = 'ses-S1';
    ses_path = fullfile( sub_path, ses_name );
    job_subj = [ job_subj sprintf('mkdir -p %s \n\n', ses_path) ];
    
    
    %% ####################################################################
    % anat
    
    ANAT_IN__serie = EXAM.getSerie( par.regextag_anat_serie, 'tag', 0 );
    
    if ~isempty(ANAT_IN__serie)
        
        if length(ANAT_IN__serie)==1 && isempty(ANAT_IN__serie.path)
            % pass, this in exeption
        else
            
            anat_OUT__dir_path = fullfile( ses_path, 'anat' );
            job_subj = [ job_subj sprintf('############\n'  ) ];
            job_subj = [ job_subj sprintf('### anat ###\n'  ) ];
            job_subj = [ job_subj sprintf('############\n\n') ];
            job_subj = [ job_subj sprintf('mkdir -p %s \n\n', anat_OUT__dir_path) ];
            
            anat_run_number = interprete_run_number( {ANAT_IN__serie.name}' );
            
            for A = 1 : numel(ANAT_IN__serie)
                
                % https://neurostars.org/t/mp2rage-in-bids-and-fmriprep/2008/4
                % https://docs.google.com/document/d/1QwfHyBzOyFWOLO4u_kkojLpUhW0-4_M7Ubafu9Gf4Gg/edit#
                if     strfind(ANAT_IN__serie(A).tag,'_INV1'  )
                    suffix_anat = 'inv-1';
                    to_remove   = length('_INV1');
                elseif strfind(ANAT_IN__serie(A).tag,'_INV2')
                    suffix_anat = 'inv-2';
                    to_remove   = length('_INV2');
                elseif strfind(ANAT_IN__serie(A).tag,'_UNI_Images')
                    suffix_anat = 'T1w';
                    to_remove   = length('_UNI_Images');
                elseif strfind(ANAT_IN__serie(A).tag,'_T1_Images')
                    suffix_anat = 'T1map';
                    to_remove   = length('_T1_Images');
                else
                    suffix_anat = 'T1w';
                    to_remove   = 0;
                end
                
                ANAT_IN___vol  = ANAT_IN__serie(A).getVolume( par.regextag_anat_volume );
                assert( ~isempty(ANAT_IN___vol) , 'Found  0/1 @volume for [ %s ] in : \n %s', par.regextag_anat_volume, ANAT_IN__serie(A).path )
                
                % Volume ------------------------------------------------------
                
                anat_OUT__name     = remove_serie_prefix(ANAT_IN___vol.serie.name);
                anat_OUT__name     = anat_OUT__name(1:end-to_remove);
                anat_OUT__name     = del_(anat_OUT__name);
                anat_OUT__name     = sprintf('acq-%s_run-%d_%s', anat_OUT__name, anat_run_number(A), suffix_anat);
                anat_OUT__base     = fullfile( anat_OUT__dir_path, sprintf('%s_%s_%s', sub_name, ses_name, anat_OUT__name) );
                anat_IN___vol_ext  = file_ext( ANAT_IN___vol.path);
                anat_OUT__vol_path = [ anat_OUT__base anat_IN___vol_ext ];
                
                job_subj = link_or_copy(job_subj, ANAT_IN___vol.path, anat_OUT__vol_path, par.copytype);
                
                % Json --------------------------------------------------------
                
                ANAT_IN__json        = ANAT_IN__serie(A).getJson( par.regextag_anat_json );
                assert( ~isempty(ANAT_IN__json)   , 'Found  0/1 @json for [ %s ] in : \n %s',                       par.regextag_anat_json, ANAT_IN__serie(A).path )
                assert(    numel(ANAT_IN__json)==1, 'Found %d/1 @json for [ %s ] in : \n %s', numel(ANAT_IN__json), par.regextag_anat_json, ANAT_IN__serie(A).path )
                
                anat_OUT__json_path = [anat_OUT__base '.json'];
                
                job_subj = link_or_copy(job_subj, ANAT_IN__json.path, anat_OUT__json_path, par.copytype);
                
                % Verbose
                if par.verbose > 1
                    fprintf('[%s]: Preparing ANAT : %s \n', mfilename, ANAT_IN___vol.path );
                end
                
            end % A
            
        end
        
    end % ANAT
    
    
    %% ####################################################################
    % func
    
    FUNC_IN__serie = EXAM.getSerie( par.regextag_func_serie, 'tag', 0 );
    
    if ~isempty(FUNC_IN__serie)
        
        if length(FUNC_IN__serie)==1 && isempty(FUNC_IN__serie.path)
            % pass, this in exeption
        else
            
            func_OUT__dir = fullfile( ses_path, 'func' );
            job_subj = [ job_subj sprintf('############\n'  ) ];
            job_subj = [ job_subj sprintf('### func ###\n'  ) ];
            job_subj = [ job_subj sprintf('############\n\n') ];
            job_subj = [ job_subj sprintf('mkdir -p %s \n\n', func_OUT__dir) ];
            
            % Compute the run number of each acquisition
            fun_run_number = interprete_run_number({FUNC_IN__serie.name}');
            
            for F = 1 : numel(FUNC_IN__serie)
                
                if     strfind(FUNC_IN__serie(F).tag,'_mag'  )
                    suffix_func = 'bold';
                elseif strfind(FUNC_IN__serie(F).tag,'_phase')
                    suffix_func = 'boldphase';
                else
                    suffix_func = 'bold';
                end
                
                FUNC_IN___vol = FUNC_IN__serie(F).getVolume( par.regextag_func_volume );
                assert(~isempty(FUNC_IN___vol), 'Found 0/1 @volume for [ %s ] in : \n %s', par.regextag_func_volume, FUNC_IN__serie(F).path )
                
                % Json ------------------------------------------------
                
                FUNC_IN__json = FUNC_IN__serie(F).getJson( par.regextag_func_json );
                assert( ~isempty(FUNC_IN__json)   , 'Found  0/1 @json for [ %s ] in : \n %s',                       par.regextag_func_json, FUNC_IN__serie(F).path )
                assert(    numel(FUNC_IN__json)==1, 'Found %d/1 @json for [ %s ] in : \n %s', numel(FUNC_IN__json), par.regextag_func_json, FUNC_IN__serie(F).path )
                
                if size(FUNC_IN___vol.path,1) == 1 % single echo **********************
                    
                    % Volume ----------------------------------------------
                    
                    func_IN___vol_path = deblank  (FUNC_IN___vol.path);
                    func_IN___vol_ext  = file_ext (func_IN___vol_path);
                    func_OUT__vol_name = remove_serie_prefix(FUNC_IN___vol.serie.name);
                    func_OUT__vol_name = del_(func_OUT__vol_name);
                    func_OUT__vol_base = fullfile( func_OUT__dir, sprintf('%s_%s_task-%s_run-%d_%s', sub_name, ses_name, func_OUT__vol_name, fun_run_number(F), suffix_func) );
                    func_OUT__vol_path = [ func_OUT__vol_base func_IN___vol_ext ];
                    
                    job_subj = link_or_copy(job_subj, FUNC_IN___vol.path, func_OUT__vol_path, par.copytype);
                    
                    % Json ------------------------------------------------
                    
                    func_OUT__json_path = [ func_OUT__vol_base '.json' ];
                    
                    % Get data from the Json that we will append on the to, to match BIDS architecture
                    json_func_struct = getJSON_params_EPI( FUNC_IN__json.path, func_OUT__vol_name );
                    
                    json_func_str = struct2jsonSTR( json_func_struct );
                    job_subj      = jobcmd_write_json_bids( job_subj, json_func_str, func_OUT__json_path, FUNC_IN__json.path );
                    
                    % Verbose
                    if par.verbose > 1
                        fprintf('[%s]: Preparing FUNC - SingleEcho : %s \n', mfilename, FUNC_IN___vol.path );
                    end
                    
                else % multi echo *****************************************
                    
                    % Json ------------------------------------------------
                    
                    allTE = cell2mat(FUNC_IN__json.getLine('EchoTime',0));
                    [sortedTE,orderTE] = sort(allTE); %#ok<ASGLU>
                    
                    % Volume ----------------------------------------------
                    
                    func_OUT__vol_name = remove_serie_prefix(FUNC_IN___vol.serie.name);
                    func_OUT__vol_name = del_(func_OUT__vol_name);
                    func_OUT__vol_base = fullfile( func_OUT__dir, sprintf('%s_%s_task-%s_run-%d', sub_name, ses_name, func_OUT__vol_name, fun_run_number(F)) );
                    
                    % Fetch volume corrsponding to the echo
                    for echo = 1 : length(orderTE)
                        
                        func_IN___vol_ext   = file_ext( deblank( FUNC_IN___vol.path(orderTE(echo),:) ) );
                        func_OUT__vol_path  = [ func_OUT__vol_base sprintf('_echo-%d_%s', echo, suffix_func) func_IN___vol_ext  ];
                        func_OUT__json_path = [ func_OUT__vol_base sprintf('_echo-%d_%s', echo, suffix_func) '.json'];
                        
                        job_subj = link_or_copy(job_subj, deblank( FUNC_IN___vol.path(orderTE(echo),:) ), func_OUT__vol_path, par.copytype);
                        
                        % Get data from the Json that we will append on the to, to match BIDS architecture
                        json_func_struct = getJSON_params_EPI( FUNC_IN__json.path(orderTE(echo),:), func_OUT__vol_name );
                        
                        json_func_str = struct2jsonSTR( json_func_struct );
                        job_subj      = jobcmd_write_json_bids( job_subj, json_func_str, func_OUT__json_path, FUNC_IN__json.path(orderTE(echo),:) );
                        
                        % Verbose
                        if par.verbose > 1
                            fprintf('[%s]: Preparing FUNC - MultiEcho - echo %d : %s \n', mfilename, echo, FUNC_IN___vol.path(orderTE(echo),:) );
                        end
                        
                    end % echo
                    
                end % single-echo / multi-echo ?
                
            end % F
            
        end
        
    end % FUNC
    
    
    %% ####################################################################
    % dwi
    
    DWI_IN__serie = EXAM.getSerie( par.regextag_dwi_serie, 'tag', 0 );
    
    if ~isempty(DWI_IN__serie)
        
        if length(DWI_IN__serie)==1 && isempty(DWI_IN__serie.path)
            % pass, this in exeption
        else
            
            dwi_OUT__dir = fullfile( ses_path, 'dwi' );
            job_subj = [ job_subj sprintf('###########\n'  ) ];
            job_subj = [ job_subj sprintf('### dwi ###\n'  ) ];
            job_subj = [ job_subj sprintf('###########\n\n') ];
            job_subj = [ job_subj sprintf('mkdir -p %s \n\n', dwi_OUT__dir) ];
            
            % Compute the run number of each acquisition
            dwi_run_number = interprete_run_number({DWI_IN__serie.name}');
            
            for D = 1 : numel(DWI_IN__serie)
                
                DWI_IN___vol  = DWI_IN__serie(D).getVolume( par.regextag_dwi_volume );
                assert(~isempty(DWI_IN___vol), 'Found 0/1 @volume for [ %s ] in : \n %s', par.regextag_dwi_volume, DWI_IN__serie.path )
                
                % Volume --------------------------------------------------
                
                dwi_IN___vol_path = deblank  (DWI_IN___vol.path);
                dwi_IN___vol_ext  = file_ext (dwi_IN___vol_path);
                dwi_OUT__vol_name = remove_serie_prefix(DWI_IN___vol.serie.name);
                dwi_OUT__vol_name = del_(dwi_OUT__vol_name);
                dwi_OUT__vol_base = fullfile( dwi_OUT__dir, sprintf('%s_%s_acq-%s_run-%d_dwi', sub_name, ses_name, dwi_OUT__vol_name, dwi_run_number(D)) );
                dwi_OUT__vol_path = [ dwi_OUT__vol_base dwi_IN___vol_ext ];
                
                job_subj = link_or_copy(job_subj, DWI_IN___vol.path, dwi_OUT__vol_path, par.copytype);
                
                % Json ----------------------------------------------------
                
                DWI_IN__json = DWI_IN__serie(D).getJson( par.regextag_dwi_json );
                assert( ~isempty(DWI_IN__json)   , 'Found  0/1 @json for [ %s ] in : \n %s',                      par.regextag_dwi_json, DWI_IN__serie(D).path )
                assert(    numel(DWI_IN__json)==1, 'Found %d/1 @json for [ %s ] in : \n %s', numel(DWI_IN__json), par.regextag_dwi_json, DWI_IN__serie(D).path )
                
                dwi_OUT__json_path = [ dwi_OUT__vol_base '.json' ];
                
                % Get data from the Json that we will append on the to, to match BIDS architecture
                json_dwi_struct = getJSON_params_EPI( DWI_IN__json.path, dwi_OUT__vol_name );
                
                json_dwi_str = struct2jsonSTR( json_dwi_struct );
                job_subj     = jobcmd_write_json_bids( job_subj, json_dwi_str, dwi_OUT__json_path, DWI_IN__json.path );
                
                % bval & bvec ---------------------------------------------
                dwi_IN___bval_path = fullfile(DWI_IN__serie(D).path,'diffusion_dir.bvals'); assert( exist(dwi_IN___bval_path,'file')==2, 'Found  0/1 file : \n %s', dwi_IN___bval_path)
                dwi_IN___bvec_path = fullfile(DWI_IN__serie(D).path,'diffusion_dir.bvecs'); assert( exist(dwi_IN___bvec_path,'file')==2, 'Found  0/1 file : \n %s', dwi_IN___bvec_path)
                dwi_OUT__bval_path = [ dwi_OUT__vol_base '.bval' ];
                dwi_OUT__bvec_path = [ dwi_OUT__vol_base '.bvec' ];
                
                job_subj = link_or_copy(job_subj, dwi_IN___bval_path, dwi_OUT__bval_path, par.copytype);
                job_subj = link_or_copy(job_subj, dwi_IN___bvec_path, dwi_OUT__bvec_path, par.copytype);
                
                % Verbose
                if par.verbose > 1
                    fprintf('[%s]: Preparing DWI : %s \n', mfilename, DWI_IN___vol.path );
                end
                
            end % D
            
        end
        
    end % DWI
    
    
    %% ####################################################################
    % fmap
    
    FMAP_IN__serie = EXAM.getSerie( par.regextag_fmap_serie, 'tag', 0 );
    
    if ~isempty(FMAP_IN__serie)
        
        if length(FMAP_IN__serie)==1 && isempty(FMAP_IN__serie.path)
            % pass, this in exeption
        else
            
            fmap_OUT__dir_path = fullfile( ses_path, 'fmap' );
            job_subj = [ job_subj sprintf('############\n'  ) ];
            job_subj = [ job_subj sprintf('### fmap ###\n'  ) ];
            job_subj = [ job_subj sprintf('############\n\n') ];
            job_subj = [ job_subj sprintf('mkdir -p %s \n\n', fmap_OUT__dir_path) ];
            
            fmap_run_number = interprete_run_number( {FMAP_IN__serie.name}' );
            
            for FM = 1 : numel(FMAP_IN__serie)
                
                FMAP_IN___vol  = FMAP_IN__serie(FM).getVolume( par.regextag_fmap_volume );
                assert( ~isempty(FMAP_IN___vol) , 'Found  0/1 @volume for [ %s ] in : \n %s', par.regextag_fmap_volume, FMAP_IN__serie.path )
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % MAGNITUDE
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if strfind(FMAP_IN__serie(FM).tag,'_mag'  )
                    
                    suffix_fmap = 'magnitude';
                    
                    for echo = 1 : size(FMAP_IN___vol.path,1)
                        
                        % Volume ------------------------------------------
                        
                        fmap_OUT__name     = remove_serie_prefix(FMAP_IN___vol.serie.name);
                        fmap_OUT__name     = del_(fmap_OUT__name);
                        fmap_OUT__name     = sprintf('acq-%s_run-%d_%s%d', fmap_OUT__name, fmap_run_number(FM), suffix_fmap, echo);
                        fmap_OUT__base     = fullfile( fmap_OUT__dir_path, sprintf('%s_%s_%s', sub_name, ses_name, fmap_OUT__name) );
                        fmap_IN___vol_ext  = file_ext( deblank(FMAP_IN___vol.path(echo,:)) );
                        fmap_OUT__vol_path = [ fmap_OUT__base fmap_IN___vol_ext ];
                        
                        job_subj = link_or_copy(job_subj, FMAP_IN___vol.path(echo,:), fmap_OUT__vol_path, par.copytype);
                        
                        % Json --------------------------------------------
                        
                        FMAP_IN__json  = FMAP_IN__serie(FM).getJson( par.regextag_fmap_json );
                        assert( ~isempty(FMAP_IN__json)   , 'Found  0/1 @json for [ %s ] in : \n %s',                       par.regextag_fmap_json, FMAP_IN__serie.path )
                        assert(    numel(FMAP_IN__json)==1, 'Found %d/1 @json for [ %s ] in : \n %s', numel(FMAP_IN__json), par.regextag_fmap_json, FMAP_IN__serie.path )
                        
                        fmap_OUT__json_path = [fmap_OUT__base '.json'];
                        
                        job_subj = link_or_copy(job_subj, FMAP_IN__json.path(echo,:), fmap_OUT__json_path, par.copytype);
                        
                        % Verbose
                        if par.verbose > 1
                            fprintf('[%s]: Preparing FMAP - Magnitude %d : %s \n', mfilename, echo, FMAP_IN___vol.path(echo,:) );
                        end
                        
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % PHASE
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                elseif strfind(FMAP_IN__serie(FM).tag,'_phase')
                    
                    suffix_fmap = 'phasediff';
                    
                    % Volume ----------------------------------------------
                    
                    fmap_OUT__name     = remove_serie_prefix(FMAP_IN___vol.serie.name);
                    fmap_OUT__name     = fmap_OUT__name(1:end-length('_phase'));
                    fmap_OUT__name     = del_(fmap_OUT__name);
                    fmap_OUT__name     = sprintf('acq-%s_run-%d_%s', fmap_OUT__name, fmap_run_number(FM), suffix_fmap);
                    fmap_OUT__base     = fullfile( fmap_OUT__dir_path, sprintf('%s_%s_%s', sub_name, ses_name, fmap_OUT__name) );
                    fmap_IN___vol_ext  = file_ext( deblank(FMAP_IN___vol.path) );
                    fmap_OUT__vol_path = [ fmap_OUT__base fmap_IN___vol_ext ];
                    
                    job_subj = link_or_copy(job_subj, FMAP_IN___vol.path, fmap_OUT__vol_path, par.copytype);
                    
                    % Json ------------------------------------------------
                    
                    FMAP_IN__json  = FMAP_IN__serie(FM).getJson( par.regextag_fmap_json );
                    assert( ~isempty(FMAP_IN__json)   , 'Found  0/1 @json for [ %s ] in : \n %s',                       par.regextag_fmap_json, FMAP_IN__serie.path )
                    assert(    numel(FMAP_IN__json)==1, 'Found %d/1 @json for [ %s ] in : \n %s', numel(FMAP_IN__json), par.regextag_fmap_json, FMAP_IN__serie.path )
                    
                    fmap_OUT__json_path = [fmap_OUT__base '.json'];
                    
                    % Get data from the Json that we will append on the to, to match BIDS architecture
                    json_fmap_struct = getJSON_params_GRE_FIELD_MAP( FMAP_IN__json.path );
                    
                    json_fmap_str = struct2jsonSTR( json_fmap_struct );
                    job_subj      = jobcmd_write_json_bids( job_subj, json_fmap_str, fmap_OUT__json_path, FMAP_IN__json.path );
                    
                    % Verbose
                    if par.verbose > 1
                        fprintf('[%s]: Preparing FMAP - Phasediff : %s \n', mfilename, FMAP_IN___vol.path );
                    end
                    
                else
                    warning('not sure what is happening here with fmap : %s', FMAP_IN__serie(FM).path)
                end
                
            end % FM
            
        end
        
    end % FMAP
    
    
    % Save job_subj
    job{e} = job_subj;
    
    if par.verbose > 1
        fprintf('\n')
    end
    
end


%% Concatenate HEADER + JOB

job = [ {job_header} ; job ];


%% Run the jobs

% Run CPU, run !
parSGE = par;
parSGE.verbose = 0; % too much display in do_cmd_sge
job = do_cmd_sge(job, parSGE);


if par.verbose > 1
    fprintf('[%s]: done %d jobs \n', mfilename, length(job) );
end


end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function run_number = interprete_run_number( names )
% Compute the run number of each acquisition

names = regexprep(names,'^S\d{2}_',''); % Remove S01_ S02_ ...
[~,~,IC] = unique(names,'stable');
run_number = nan(size(IC));
for idx = 1 : numel(IC)
    run_number(idx) = sum( IC(idx)==IC(1:idx) );
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function name = remove_serie_prefix(str)

name = regexprep(str,'^S\d+_','');

end % function

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function name = remove_volume_prefix(str)
%
% name = regexprep(str,'^(f|s)\d+_S\d+_','');
%
% end % function

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function run_number = fetch_run_number(obj)
%
% run_number = regexp(obj.tag,'_\d+$','match');
% if ~isempty(run_number)
%     run_number = str2double(run_number{1}(2:end));
% else
%     error('Unknown run number for tag=%s : %s', obj.tag, obj.path)
% end
%
% end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = del_(in)

out = strrep(in,'_','');

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = file_ext(in)

% File extension ?
if strcmp(in(end-6:end),'.nii.gz')
    out = '.nii.gz';
elseif strcmp(in(end-3:end),'.nii')
    out = '.nii';
else
    error('WTF ? supported files are .nii and .nii.gz')
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function job_subj = link_or_copy(job_subj, IN_path, OUT_path, type)

switch type
    case 'link'
        job_subj   = [ job_subj sprintf('ln -sf %s %s \n\n', IN_path, OUT_path) ];
    case 'copy'
        job_subj   = [ job_subj sprintf( 'cp -f %s %s \n\n', IN_path, OUT_path) ];
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function job_subj = jobcmd_write_json_bids( job_subj, json_str, newJSON_path, prevJSON_path  )
% Write BIDS data in the new JSON file, and append the previous JSON file

if nargin > 3 % concatenate json_str + prevJSON_path content and write
    new_str  = sprintf('%s,\n',json_str(1:end-2));
    job_subj = [ job_subj sprintf('echo ''%s''>> %s \n\n'    , new_str       , newJSON_path ) ];
    job_subj = [ job_subj sprintf('tail -n +2 %s  >> %s \n\n', prevJSON_path , newJSON_path ) ];
else % just write json_str
    job_subj = [ job_subj sprintf('echo ''%s''>> %s \n\n'    , json_str      , newJSON_path ) ];
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function json_str = struct2jsonSTR( structure )

% Prepare info for .json BIDS
fields = fieldnames( structure );

% Initialize the output
json_str = sprintf('{\n');

for idx = 1:numel(fields)
    
    switch class( structure.(fields{idx}) )
        
        case 'double'
            if numel(structure.(fields{idx})) == 1
                json_str = [json_str sprintf( '\t "%s": %g,\n', fields{idx}, structure.(fields{idx}) ) ];
            else
                % Concatenation
                rep      = repmat( '%g, ', [1 length(structure.(fields{idx}))] );
                rep      = rep(1:end-2);
                rep      = ['[' rep ']'];
                final    = sprintf(rep, structure.(fields{idx}) );
                json_str = [json_str sprintf( '\t "%s": %s,\n', fields{idx}, final ) ];
            end
            
        case 'char'
            json_str = [json_str sprintf( '\t "%s": "%s",\n', fields{idx}, structure.(fields{idx}) ) ];
            
        case 'cell'
            % Concatenation
            rep      = repmat( '"%s", ', [1 length(structure.(fields{idx}))] );
            rep      = rep(1:end-2);
            rep      = ['[' rep ']'];
            final    = sprintf(rep, structure.(fields{idx}){:} );
            json_str = [json_str sprintf( '\t "%s": %s,\n', fields{idx}, final ) ];
            
    end
    
end % fields

json_str = [ json_str(1:end-2) sprintf('\n}') ]; % delete the last ',\n" and close the json

end % end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function json_func_struct = getJSON_params_EPI( json_path, TaskName )

res = get_string_from_json(json_path, ...
    {'RepetitionTime', 'EchoTime', 'CsaImage.MosaicRefAcqTimes', 'FlipAngle', ...
    'CsaSeries.MrPhoenixProtocol.sPat.lAccelFactPE', 'CsaSeries.MrPhoenixProtocol.sWipMemBlock.alFree\[13\]','MagneticFieldStrength',...
    'NumberOfPhaseEncodingSteps','CsaImage.BandwidthPerPixelPhaseEncode',...
    'InPlanePhaseEncodingDirection','CsaImage.PhaseEncodingDirectionPositive'}, ...
    {'num', 'num', 'vect', 'num',...
    'num','num','num',...
    'num','num',...
    'str','num'});

% Classic
json_func_struct.TaskName       = TaskName;
json_func_struct.RepetitionTime = res{1}/1000; % ms -> s
json_func_struct.EchoTime       = res{2}/1000; % ms -> s
json_func_struct.SliceTiming    = res{3}/1000; % ms -> s
json_func_struct.FlipAngle      = res{4};

% Acceleration factors
if ~isempty(res{5})
    json_func_struct.ParallelReductionFactorInPlane = res{5}; % iPat
end
if ~isempty(res{6})
    json_func_struct.MultibandAccelerationFactor = res{6}; % MultiBand
end
json_func_struct.MagneticFieldStrength = res{7};

% Phase : echo spacing stuff
ReconMatrixPE        = res{8}; % NumberOfPhaseEncodingSteps
BWPPPE               = res{9}; % BandwidthPerPixelPhaseEncode
EffectiveEchoSpacing = 1 / (BWPPPE * ReconMatrixPE); % SIEMENS
TotalReadoutTime     = EffectiveEchoSpacing * (ReconMatrixPE - 1); % FSL
json_func_struct.EffectiveEchoSpacing = EffectiveEchoSpacing;
json_func_struct.TotalReadoutTime     = TotalReadoutTime;

% Phase : encoding direction
switch res{10} % InPlanePhaseEncodingDirection
    case 'COL'
        phase_dir = 'j';
    case 'ROW'
        phase_dir = 'i';
end
if res{11} % PhaseEncodingDirectionPositive
    phase_dir = [phase_dir '-'];
end
json_func_struct.PhaseEncodingDirection = phase_dir;

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function json_func_struct = getJSON_params_GRE_FIELD_MAP( json_path )

res = get_string_from_json(json_path, ...
    {'RepetitionTime', 'EchoTime', 'FlipAngle', ...
    'CsaSeries.MrPhoenixProtocol.sPat.lAccelFactPE','MagneticFieldStrength',...
    'InPlanePhaseEncodingDirection','CsaImage.PhaseEncodingDirectionPositive'}, ...
    {'num', 'num', 'num',...
    'num','num',...
    'str','num'});

% Classic
json_func_struct.EchoTime1      = (res{2}-2.46)/1000; % ms -> s % the difference is only 2.46ms for SIEMENS scanners with gre_field_map
json_func_struct.EchoTime2      =  res{2}      /1000; % ms -> s
json_func_struct.RepetitionTime = res{1}/1000; % ms -> s
json_func_struct.FlipAngle      = res{3};

% Acceleration factors
if ~isempty(res{4})
    json_func_struct.ParallelReductionFactorInPlane = res{4}; % iPat
end
json_func_struct.MagneticFieldStrength = res{5};

% Phase : encoding direction
switch res{6} % InPlanePhaseEncodingDirection
    case 'COL'
        phase_dir = 'j';
    case 'ROW'
        phase_dir = 'i';
end
if res{7} % PhaseEncodingDirectionPositive
    phase_dir = [phase_dir '-'];
end
json_func_struct.PhaseEncodingDirection = phase_dir;

end % function
