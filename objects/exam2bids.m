function [ job ] = exam2bids( examArray , bidsDir , par )
%EXAM2BIDS


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

assert( isa( examArray, 'exam' ), 'examArray must be a @exam object array' )
assert( ischar(bidsDir)         , 'bidsDir must be a dir'                  )


%% defpar

defpar.sge      = 0;
defpar.jobname  = 'matvol_exam2bids';
defpar.walltime = '00:30:00';
defpar.pct      = 0;

defpar.redo     = 0;
defpar.run      = 0;
defpar.display  = 0;
par.verbose     = 2;

par = complet_struct(par,defpar);


%% Prepare all commands

fprintf('\n')

nrExam = numel(examArray);
job = cell(nrExam,1); % pre-allocation, this is the job containter

[SUCCESS,MESSAGE] = mkdir(bidsDir);
if ~SUCCESS
    error('%s : bidsDir', MESSAGE)
end

for e = 1:nrExam
    
    E = examArray(e); % shortcut (E is a pointer, not a copy of the object)
    
    % Echo in terminal & initialize job_subj
    fprintf('[%s]: Preparing JOB %d/%d for %s \n', mfilename, e, nrExam, E.path);
    job_subj = sprintf('#################### [%s] JOB %d/%d for %s #################### \n', mfilename, e, nrExam, E.path); % initialize
    
    %----------------------------------------------------------------------
    % sub DIR
    sub_name = sprintf('sub-%s',del_(E.name));
    sub_path = fullfile( bidsDir, sub_name );
    job_subj = [ job_subj sprintf('mkdir %s \n', sub_path) ]; %#ok<*AGROW>
    
    %----------------------------------------------------------------------
    % ses-Sx DIR
    ses_name = 'ses-S1';
    ses_path = fullfile( sub_path, ses_name );
    job_subj = [ job_subj sprintf('mkdir %s \n', ses_path) ];
    
    %----------------------------------------------------------------------
    % ANAT
    
    A = E.getSerie('anat');
    
    if ~isempty(A)
        if numel(A)==1
            
            anat_path = fullfile( ses_path, 'anat' );
            job_subj = [ job_subj sprintf('### anat ###\n') ];
            job_subj = [ job_subj sprintf('mkdir %s \n', anat_path) ];
            
            %------------------------------------------------------------------
            % anat NII/NII.GZ & JSON
            
            % Volume
            T1w_vol = A.getVolume('T1w');
            assert( ~isempty(T1w_vol), 'Found 0/1 @volume found for [ T1w ] in : \n %s' , numel(A), A.path )
            assert( numel(A)==1      , 'Found %d/1 @volume found for [ T1w ] in : \n %s', numel(A), A.path )
            T1w_name = 'T1w';
            T1w_base = fullfile( anat_path, sprintf('%s_%s_%s', sub_name, ses_name, T1w_name) );
            [~,~,T1w_ext] = fileparts(T1w_vol.path);
            T1w_vol_path = [T1w_base T1w_ext];
            job_subj = [ job_subj sprintf('ln -sf %s %s \n', T1w_vol.path, T1w_vol_path) ];
            
            % Json
            T1w_json = A.getJson('j');
            assert( ~isempty(T1w_json), 'No @json found for [ j ] in : \n %s'                  , A.path )
            assert( numel(A)==1       , 'Found %d/1 @json found for [ j ] in : \n %s', numel(A), A.path )
            T1w_json_path = [T1w_base '.json'];
            job_subj = [ job_subj sprintf('ln -sf %s %s \n', T1w_json.path, T1w_json_path) ];
            
        else
            warning( 'Found %d/1 @serie found for [ anat ] in : \n %s', numel(A), E.path )
        end
        
    end % ANAT
    
    %----------------------------------------------------------------------
    % FUNC
    
    F = E.getSerie('func');
    
    if ~isempty(F)
        
        if length(F)==1 && isempty(F.path)
            % pass, this in exeption
        else
            
            func_path = fullfile( ses_path, 'func' );
            job_subj = [ job_subj sprintf('### func ###\n') ];
            job_subj = [ job_subj sprintf('mkdir %s \n', func_path) ];
            
            for f = 1 : numel(F)
                
                V = F(f).getVolume('f');
                assert( ~isempty(V), 'Found 0/1 @volume found for [ func ] in : \n %s' , F.path )
                
                % Volume
                [~,V_name,V_ext] = fileparts(V.path);
                V_name = del_(V_name);
                V_base = fullfile( func_path, sprintf('%s_%s_task-%s_bold', sub_name, ses_name, V_name) );
                V_vol_path = [ V_base V_ext ];
                job_subj = [ job_subj sprintf('ln -sf %s %s \n', V.path, V_vol_path) ];
                
                % Json
                J = F(f).getJson('j');
                assert( ~isempty(J), 'No @json found for [ j ] in : \n %s'                  , F.path )
                assert( numel(J)==1, 'Found %d/1 @json found for [ j ] in : \n %s', numel(J), F.path )
                J_path = [V_base '.json'];
                job_subj = [ job_subj sprintf('ln -sf %s %s \n', J.path, J_path) ];
                
            end % f
            
        end
        
    end % FUNC
    
    % Save job_subj
    job{e} = job_subj;
    
    
end


%% Run the jobs

% Run CPU, run !
job = do_cmd_sge(job, par);


end % function

function out = del_(in)

out = strrep(in,'_','');

end % function