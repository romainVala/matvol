function [ job ] = exam2bids( examArray , bidsDir , par )
%EXAM2BIDS


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

assert( isa( examArray, 'exam' ), 'examArray must be a @exam object array' )
assert( ischar(bidsDir)         , 'bidsDir must be a dir'                  )


%% defpar

defpar.regex_anat = 'anat';
defpar.regex_func = 'func';
defpar.regex_json = 'json';

defpar.sge      = 0;
defpar.jobname  = 'matvol_exam2bids';
defpar.walltime = '00:30:00';
defpar.pct      = 0;

defpar.redo     = 0;
defpar.run      = 0;
defpar.display  = 0;
defpar.verbose  = 2;

par = complet_struct(par,defpar);


%% Prepare all commands

if par.verbose > 0
    fprintf('\n')
end

nrExam = numel(examArray);
job = cell(nrExam,1); % pre-allocation, this is the job containter

[SUCCESS,MESSAGE] = mkdir(bidsDir);
if ~SUCCESS
    error('%s : bidsDir', MESSAGE)
end


%% --------------------------------------------------------------------
% dataset_description.json

% Name
study_path = examArray(1).path;
if strcmp(study_path(end),filesep), study_path = study_path(1:end-1); end % remove '/' at the end, if exists
study_path = fileparts(study_path);
dataset_description.Name = study_path; % dir of the study, such as /export/dataCENIR/dicom/nifti_raw/PRISMA_STIMPNEE

% BIDSVersion
dataset_description.BIDSVersion = '1.1.1';

% License
dataset_description.License = 'PDDL';

% Authors
dataset_description.Authors = {'CENIR-ICM', 'Romain Valabrègue', 'Benoît Béranger'};

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

json_bids = struct2json( dataset_description );
job_header = sprintf('## dataset_description.json ## \n');
job_header = write_json_bids( job_header, json_bids, fullfile(bidsDir,'dataset_description.json') );


%% Main loop

for e = 1:nrExam
    %% --------------------------------------------------------------------
    % Initialization
    
    E = examArray(e); % shortcut (E is a pointer, not a copy of the object)
    
    % Echo in terminal & initialize job_subj
    if par.verbose > 0
        fprintf('[%s]: Preparing JOB %d/%d for %s \n', mfilename, e, nrExam, E.path);
    end
    job_subj = sprintf('#################### [%s] JOB %d/%d for %s #################### \n', mfilename, e, nrExam, E.path); % initialize
    %#ok<*AGROW>
    
    
    %% --------------------------------------------------------------------
    % sub DIR
    sub_name = sprintf('sub-%s',del_(E.name));
    sub_path = fullfile( bidsDir, sub_name );
    job_subj = [ job_subj sprintf('mkdir -p %s \n', sub_path) ];
    
    
    %% --------------------------------------------------------------------
    % ses-Sx DIR
    ses_name = 'ses-S1';
    ses_path = fullfile( sub_path, ses_name );
    job_subj = [ job_subj sprintf('mkdir -p %s \n', ses_path) ];
    
    
    %% --------------------------------------------------------------------
    % ANAT
    
    A = E.getSerie( par.regex_anat );
    
    if ~isempty(A)
        if numel(A)==1
            
            anat_path = fullfile( ses_path, 'anat' );
            job_subj = [ job_subj sprintf('### anat ###\n') ];
            job_subj = [ job_subj sprintf('mkdir -p %s \n', anat_path) ];
            
            % Volume ......................................................
            T1w_vol = A.getVolume('T1w');
            assert( ~isempty(T1w_vol), 'Found 0/1 @volume found for [ T1w ] in : \n %s' , numel(A), A.path )
            assert( numel(A)==1      , 'Found %d/1 @volume found for [ T1w ] in : \n %s', numel(A), A.path )
            T1w_name = 'T1w';
            T1w_base = fullfile( anat_path, sprintf('%s_%s_%s', sub_name, ses_name, T1w_name) );
            T1w_ext = file_ext(T1w_vol.path);
            T1w_vol_path = [T1w_base T1w_ext];
            job_subj = [ job_subj sprintf('ln -sf %s %s \n', T1w_vol.path, T1w_vol_path) ];
            
            % Json ........................................................
            T1w_json = A.getJson( par.regex_json );
            assert( ~isempty(T1w_json), 'No @json found for [ j ] in : \n %s'                  , A.path )
            assert( numel(A)==1       , 'Found %d/1 @json found for [ j ] in : \n %s', numel(A), A.path )
            T1w_json_path = [T1w_base '.json'];
            job_subj = [ job_subj sprintf('ln -sf %s %s \n', T1w_json.path, T1w_json_path) ];
            
            % Echo
            if par.verbose > 1
                fprintf('[%s]: Preparing ANAT : %s \n', mfilename, T1w_vol.path );
            end
        else
            warning( 'Found %d/1 @serie found for [ anat ] in : \n %s', numel(A), E.path )
        end
        
    end % ANAT
    
    
    %% --------------------------------------------------------------------
    % FUNC
    
    F = E.getSerie( par.regex_func );
    
    if ~isempty(F)
        
        if length(F)==1 && isempty(F.path)
            % pass, this in exeption
        else
            
            func_path = fullfile( ses_path, 'func' );
            job_subj = [ job_subj sprintf('### func ###\n') ];
            job_subj = [ job_subj sprintf('mkdir -p %s \n', func_path) ];
            
            for f = 1 : numel(F)
                
                V = F(f).getVolume('f');
                assert( ~isempty(V), 'Found 0/1 @volume found for [ func ] in : \n %s' , F.path )
                
                if size(V.path,1) == 1 % single echo **********************
                    
                    % Volume ..............................................
                    file_path = deblank(V.path);
                    V_ext = file_ext(file_path);
                    [~,V_name,~] = fileparts(V.path(1:end-length(V_ext)));
                    V_name = del_(V_name);
                    V_base = fullfile( func_path, sprintf('%s_%s_task-%s_bold', sub_name, ses_name, V_name) );
                    V_vol_path = [ V_base V_ext ];
                    job_subj = [ job_subj sprintf('ln -sf %s %s \n', V.path, V_vol_path) ];
                    
                    % Json ................................................
                    J = F(f).getJson( par.regex_json );
                    assert( ~isempty(J), 'No @json found for [ j ] in : \n %s'                  , F.path )
                    assert( numel(J)==1, 'Found %d/1 @json found for [ j ] in : \n %s', numel(J), F.path )
                    J_path = [V_base '.json'];
                    
                    % Get data from the Json that we will append on the to, to match BIDS architecture
                    [ res ] = get_string_from_json(J.path, ...
                        {'RepetitionTime', 'EchoTime', 'CsaImage.MosaicRefAcqTimes', 'FlipAngle', 'CsaSeries.MrPhoenixProtocol.sPat.lAccelFactPE'}, ...
                        {'num', 'num', 'vect', 'num','num'});
                    to_write.RepetitionTime = res{1}/1000; % ms -> s
                    to_write.EchoTime       = res{2}/1000; % ms -> s
                    to_write.SliceTiming    = res{3}/1000; % ms -> s
                    to_write.FlipAngle      = res{4};
                    to_write.ParallelReductionFactorInPlane = res{5};
                    to_write.TaskName       = V.name(1:end-length(V_ext));
                    
                    json_bids = struct2json( to_write );
                    job_subj = write_json_bids( job_subj, json_bids, J_path );
                    
                    % Echo
                    if par.verbose > 1
                        fprintf('[%s]: Preparing FUNC - SingleEcho : %s \n', mfilename, V.path );
                    end
                    
                else % multi echo *****************************************
                    
                    % Json ................................................
                    J = F(f).getJson( par.regex_json );
                    assert( ~isempty(J), 'No @json found for [ j ] in : \n %s'                  , F.path )
                    assert( numel(J)==1, 'Found %d/1 @json found for [ j ] in : \n %s', numel(J), F.path )
                    
                    allTE = cell2mat(J.getLine('EchoTime',0));
                    [sortedTE,order] = sort(allTE); %#ok<ASGLU>
                    
                    % Volume ..............................................
                    % Fetch volume extension, because MATLAB's fileparts.m function is stupid : it doesnt understand .nii.gz
                    file_1_path = deblank(V.path(1,:));
                    V_ext = file_ext(file_1_path);
                    [~,V_name,~] = fileparts( file_1_path(1:end-length(V_ext)) ); % Remove the extension before calling 'fileparts' function
                    V_name = del_(V_name);
                    V_base = fullfile( func_path, sprintf('%s_%s_task-%s', sub_name, ses_name, V_name) );
                    
                    % Fetch volume corrsponding to the echo
                    for echo = 1 : length(order)
                        
                        V_ext = file_ext( deblank( V.path(order(echo),:) ) );
                        ln_vol_path  = [ V_base sprintf('_echo-%d_bold',echo) V_ext  ];
                        ln_json_path = [ V_base sprintf('_echo-%d_bold',echo) '.json'];
                        
                        job_subj = [ job_subj sprintf('ln -sf %s %s \n', deblank( V.path(order(echo),:) ), ln_vol_path ) ];
                        
                        % Get data from the Json that we will append on the to, to match BIDS architecture
                        [ res ] = get_string_from_json(J.path(order(echo),:), ...
                            {'RepetitionTime', 'EchoTime', 'CsaImage.MosaicRefAcqTimes', 'FlipAngle', 'CsaSeries.MrPhoenixProtocol.sPat.lAccelFactPE'}, ...
                            {'num', 'num', 'vect', 'num','num'});
                        to_write.RepetitionTime = res{1}/1000; % ms -> s
                        to_write.EchoTime       = res{2}/1000; % ms -> s
                        to_write.SliceTiming    = res{3}/1000; % ms -> s
                        to_write.FlipAngle      = res{4};
                        to_write.ParallelReductionFactorInPlane = res{5};
                        echo_x_name = deblank(V.name(order(echo),:));
                        echo_x_name = echo_x_name(1:end-length(V_ext));
                        if order(echo) > 1
                            echo_x_name = echo_x_name(1:end-5); % delete _V00X (echo name);
                        end
                        to_write.TaskName       = echo_x_name;
                        
                        json_bids = struct2json( to_write );
                        job_subj = write_json_bids( job_subj, json_bids, ln_json_path );
                        
                        % Echo
                        if par.verbose > 1
                            fprintf('[%s]: Preparing FUNC - MultiEcho - echo %d : %s \n', mfilename, echo, V.path(order(echo),:) );
                        end
                        
                    end % echo
                    
                end % single-echo / multi-echo ?
                
            end % f
            
        end
        
    end % FUNC
    
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
par.verbose = 0; % too much display in do_cmd_sge
job = do_cmd_sge(job, par);


end % function

function out = del_(in)

out = strrep(in,'_','');

end % function

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

function job_subj = write_json_bids( job_subj, json_bids, newJSON, prevJSON  )

% Write BIDS data in the new JSON file, and append the previous JSON file
job_subj = [ job_subj sprintf('echo ''%s'' >> %s \n', json_bids , newJSON ) ];
% job_subj = [ job_subj sprintf('cat %s >> %s \n', prevJSON , newJSON ) ];

end % function

function json_bids = struct2json( input_structure )

% Prepare info for .json BIDS
fields = fieldnames(input_structure);
json_bids = sprintf('{\n');
for idx = 1:numel(fields)
    switch class(input_structure.(fields{idx}))
        
        case 'double'
            if numel(input_structure.(fields{idx})) == 1
                json_bids = [json_bids sprintf( '\t "%s": %g,\n', fields{idx}, input_structure.(fields{idx}) ) ];
            else
                % Concatenation
                rep  = repmat('%g, ',[1 length(input_structure.(fields{idx}))]);
                rep  = rep(1:end-2);
                rep   = ['[' rep ']'];
                final = sprintf(rep,input_structure.(fields{idx}));
                json_bids = [json_bids sprintf( '\t "%s": %s,\n', fields{idx}, final ) ];
            end
            
        case 'char'
            json_bids = [json_bids sprintf( '\t "%s": "%s",\n', fields{idx}, input_structure.(fields{idx}) ) ];
            
        case 'cell'
            % Concatenation
            rep  = repmat('"%s", ',[1 length(input_structure.(fields{idx}))]);
            rep  = rep(1:end-2);
            rep   = ['[' rep ']'];
            final = sprintf(rep,input_structure.(fields{idx}){:});
            json_bids = [json_bids sprintf( '\t "%s": %s,\n', fields{idx}, final ) ];
            
    end
end % fields
json_bids = [ json_bids(1:end-2) sprintf('\n}') ];

end % end
