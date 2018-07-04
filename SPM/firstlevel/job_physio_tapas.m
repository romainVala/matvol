function [ jobs ]= job_physio_tapas( dirFunc, dirPhysio, par)
% JOB_PHYSIO_TAPAS - SPM:tools:physio
% Use 2-level cell (get_subdir_regex_multi) syntax for dirFunc & dirPhysio


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.file_reg = '^f.*nii';

defpar.rp       = 1;
defpar.rp_regex = '^rp.*txt';
defpar.rp_order = 24; % can be 6, 12, 24 : 6 = just add rp, 12 = also adds first order derivatives, 24 = also adds first + second order derivatives

defpar.print_figures = 0; % 0 , 1 , 2 , 3

defpar.jobname  = 'spm_physio';
defpar.walltime = '04:00:00';
defpar.sge      = 0;

defpar.run      = 0;
defpar.display  = 0;
defpar.redo     = 0;

par = complet_struct(par,defpar);


%% Prepare job

nrSubject = length(dirFunc);

j = 0; % counter

p.verbose = 0;

skip = [];

for subj = 1:nrSubject
    
    nrRun = length(dirFunc{subj});
    
    for run = 1:nrRun
        
        j = j + 1; % counter
        
        % Save dir --------------------------------------------------------
        
        jobs{j}.spm.tools.physio.save_dir = dirFunc{subj}(run); %#ok<*AGROW>
        
        outputfile = fullfile(dirFunc{subj}{run},'multiple_regressors.txt');
        if ~par.redo && exist(outputfile,'file')
            skip = [skip j];
            fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,outputfile);
            continue
        end
        
        % Physio files ----------------------------------------------------
        
        rawphysio = get_subdir_regex_files( dirPhysio{subj}{run} , 'UNKNOWN.dic$' , 1 );
        
        Info      = get_subdir_regex_files( dirPhysio{subj}{run} , '_Info.log$' , p );
        PULSE     = get_subdir_regex_files( dirPhysio{subj}{run} , '_PULS.log$' , p );
        RESP      = get_subdir_regex_files( dirPhysio{subj}{run} , '_RESP.log$' , p );
        
        if isempty(Info) || isempty(PULSE) || isempty(RESP)
            extractCMRRPhysio( char(rawphysio) )
            Info  = get_subdir_regex_files( dirPhysio{subj}{run} , '_Info.log$' , 1 );
            PULSE = get_subdir_regex_files( dirPhysio{subj}{run} , '_PULS.log$' , 1 );
            RESP  = get_subdir_regex_files( dirPhysio{subj}{run} , '_RESP.log$' , 1 );
        end
        
        jobs{j}.spm.tools.physio.log_files.vendor = 'Siemens_Tics'; % Siemens CMRR multiband sequence
        jobs{j}.spm.tools.physio.log_files.cardiac = PULSE;
        jobs{j}.spm.tools.physio.log_files.respiration = RESP;
        jobs{j}.spm.tools.physio.log_files.scan_timing = Info;
        jobs{j}.spm.tools.physio.log_files.sampling_interval = [];
        jobs{j}.spm.tools.physio.log_files.relative_start_acquisition = 0;
        jobs{j}.spm.tools.physio.log_files.align_scan = 'last';
        
        % Volume info -----------------------------------------------------
        
        volumes = get_subdir_regex_files( dirFunc{subj}(run) , par.file_reg , p ); % Can be more than 1 volume in case of multi-echo.
        volume  = volumes{1};                                                      % Only use the first volume. In case of ME, all volumes have the same 4D-matrix.
        V       = spm_vol(char(volume));                                           % Read volume header
        
        nrVolumes = length(V);
        nrSlices  = V(1).dim(3);
        TR        = V(1).private.timing.tspace;
        
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Nslices = nrSlices;
        jobs{j}.spm.tools.physio.scan_timing.sqpar.NslicesPerBeat = [];
        jobs{j}.spm.tools.physio.scan_timing.sqpar.TR = TR;
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Ndummies = 0;
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Nscans = nrVolumes;
        jobs{j}.spm.tools.physio.scan_timing.sqpar.onset_slice = round(nrSlices/2);
        jobs{j}.spm.tools.physio.scan_timing.sqpar.time_slice_to_slice = [];
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Nprep = [];
        jobs{j}.spm.tools.physio.scan_timing.sync.scan_timing_log = struct([]);
        jobs{j}.spm.tools.physio.preproc.cardiac.modality = 'PPU';
        jobs{j}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.min = 0.4;
        jobs{j}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.file = 'initial_cpulse_kRpeakfile.mat';
        jobs{j}.spm.tools.physio.preproc.cardiac.posthoc_cpulse_select.off = struct([]);
        jobs{j}.spm.tools.physio.model.output_multiple_regressors = 'multiple_regressors.txt';
        jobs{j}.spm.tools.physio.model.output_physio = 'physio.mat';
        jobs{j}.spm.tools.physio.model.orthogonalise = 'none';
        jobs{j}.spm.tools.physio.model.retroicor.yes.order.c = 3;
        jobs{j}.spm.tools.physio.model.retroicor.yes.order.r = 4;
        jobs{j}.spm.tools.physio.model.retroicor.yes.order.cr = 1;
        jobs{j}.spm.tools.physio.model.rvt.yes.delays = 0;
        jobs{j}.spm.tools.physio.model.hrv.yes.delays = 0;
        jobs{j}.spm.tools.physio.model.noise_rois.no = struct([]);
        
        % Realignment parameters-------------------------------------------
        
        if par.rp
            rp = get_subdir_regex_files( dirFunc{subj}(run) , par.rp_regex , 1 );
            jobs{j}.spm.tools.physio.model.movement.yes.file_realignment_parameters = rp;
            jobs{j}.spm.tools.physio.model.movement.yes.order = par.rp_order;
            jobs{j}.spm.tools.physio.model.movement.yes.outlier_translation_mm = Inf;
            jobs{j}.spm.tools.physio.model.movement.yes.outlier_rotation_deg = Inf;
        end
        
        jobs{j}.spm.tools.physio.model.other.no = struct([]);
        jobs{j}.spm.tools.physio.verbose.level = par.print_figures;
        jobs{j}.spm.tools.physio.verbose.fig_output_file = '';
        jobs{j}.spm.tools.physio.verbose.use_tabs = false;
        
    end
    
end

%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


end % function

