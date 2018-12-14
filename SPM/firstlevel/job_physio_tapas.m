function [ jobs ]= job_physio_tapas( dirFunc, dirPhysio, dirNoiseROI, par)
% JOB_PHYSIO_TAPAS - SPM:tools:physio
% Use 2-level cell (get_subdir_regex_multi) syntax for dirFunc & dirPhysio


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.logfiles_vendor     = 'Siemens_Tics'; % Siemens CMRR multiband sequence, only this one is coded yet
defpar.logfiles_align_scan = 'last';         % 'last' / 'first'
% Determines which scan shall be aligned to which part of the logfile.
% Typically, aligning the last scan to the end of the logfile is beneficial, since start of logfile and scans might be shifted due to pre-scans;

defpar.file_reg = '^f.*nii'; % to fetch volume info (nrVolumes, nrSlices, TR, ...)

defpar.slice_to_realign = 'middle'; % 'first' / 'middle' / 'last' / sliceNumber (integer)
% Slice to which regressors are temporally aligned. Typically the slice where your most important activation is expected.

% Physio regressors types
defpar.usePhysio = 1;
defpar.RETROICOR = 1;
defpar.RVT       = 1;
defpar.HRV       = 1;

% Noise ROI regressors
defpar.noiseROI = 1;
defpar.noiseROI_files_regex  = '^w.*nii';       % usually use normalied files, NOT the smoothed data
defpar.noiseROI_mask_regex   = '^rwc[23].*nii'; % 2 = WM, 3 = CSF
defpar.noiseROI_thresholds   = [0.95 0.95];     % keep voxels with tissu probabilty >= 95%
defpar.noiseROI_n_voxel_crop = [2 1];           % crop n voxels in each direction, to avoid partial volume
defpar.noiseROI_n_components = 10;              % keep n PCA componenets

% Movement regressors
defpar.rp           = 1;
defpar.rp_regex     = '^rp.*txt';
defpar.rp_order     = 24; % can be 6, 12, 24
% 6 = just add rp, 12 = also adds first order derivatives, 24 = also adds first + second order derivatives
defpar.rp_method    = 'FD'; % 'MAXVAL' / 'FD' / 'DVARS'
defpar.rp_threshold = 0.5;  % Threshold above which a stick regressor is created for corresponding volume of exceeding value

par.other_regressor_regex = ''; % if you want to add other ones...

defpar.print_figures = 1; % 0 , 1 , 2 , 3

defpar.jobname  = 'spm_physio';
defpar.walltime = '04:00:00';
defpar.sge      = 0;

defpar.run      = 1;
defpar.display  = 0;
defpar.redo     = 0;

par = complet_struct(par,defpar);


%% Prepare job

nrSubject = length(dirFunc);

j = 0; % counter

p.verbose = 0;

skip = [];

if ~par.usePhysio
    par.RETROICOR = 0;
    par.RVT       = 0;
    par.HRV       = 0;
end

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
        
        if par.usePhysio
            
            % Physio files ----------------------------------------------------
            
            if ~strcmp(par.logfiles_vendor,'Siemens_Tics')
                error('[%s] only "%s" is coded yet', mfilename, 'Siemens_Tics' )
            end
            
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
            
            jobs{j}.spm.tools.physio.log_files.vendor = par.logfiles_vendor;
            jobs{j}.spm.tools.physio.log_files.cardiac = PULSE;
            jobs{j}.spm.tools.physio.log_files.respiration = RESP;
            jobs{j}.spm.tools.physio.log_files.scan_timing = Info;
            jobs{j}.spm.tools.physio.log_files.sampling_interval = [];
            jobs{j}.spm.tools.physio.log_files.relative_start_acquisition = 0;
            jobs{j}.spm.tools.physio.log_files.align_scan = 'last';
            
        else
            
            jobs{j}.spm.tools.physio.log_files.cardiac     = {''};
            jobs{j}.spm.tools.physio.log_files.respiration = {''};
            jobs{j}.spm.tools.physio.log_files.scan_timing = {''};
            
        end
        
        % Volume info -----------------------------------------------------
        
        % from header extracted by SPM
        volumes = get_subdir_regex_files( dirFunc{subj}(run) , par.file_reg , p ); % Can be more than 1 volume in case of multi-echo.
        volume  = volumes{1};                                                      % Only use the first volume. In case of ME, all volumes have the same 4D-matrix.
        V       = spm_vol_nifti(char(volume));                                     % Read volume header
        nrVolumes = V.private.dat.dim(4);
        nrSlices  = V.private.dat.dim(3);
        
        % from JSON extracted by matvol functions
        json = get_subdir_regex_files( dirFunc{subj}(run) , 'json$' , p );
        json = char(json{1});
        res  = get_string_from_json(json, {'RepetitionTime'}, {'num'});
        TR   = res{1}/1000; % ms -> s
        
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Nslices = nrSlices;
        jobs{j}.spm.tools.physio.scan_timing.sqpar.NslicesPerBeat = [];
        jobs{j}.spm.tools.physio.scan_timing.sqpar.TR = TR;
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Ndummies = 0; % no dummy scan with Siemmens scanner
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Nscans = nrVolumes;
        switch par.slice_to_realign
            case 'first'
                onset_slice = 1;
            case 'middle'
                onset_slice = round(nrSlices/2);
            case 'last'
                onset_slice = nrSlices;
            otherwise
                onset_slice = par.slice_to_realign; % integer
        end
        jobs{j}.spm.tools.physio.scan_timing.sqpar.onset_slice = onset_slice;
        jobs{j}.spm.tools.physio.scan_timing.sqpar.time_slice_to_slice = [];
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Nprep = [];
        jobs{j}.spm.tools.physio.scan_timing.sync.scan_timing_log = struct([]);
        jobs{j}.spm.tools.physio.preproc.cardiac.modality = 'PPU'; % Siemens pulse oxymeter device
        jobs{j}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.min = 0.4;
        jobs{j}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.file = 'initial_cpulse_kRpeakfile.mat';
        jobs{j}.spm.tools.physio.preproc.cardiac.posthoc_cpulse_select.off = struct([]);
        jobs{j}.spm.tools.physio.model.output_multiple_regressors = 'multiple_regressors.txt';
        jobs{j}.spm.tools.physio.model.output_physio = 'physio.mat';
        jobs{j}.spm.tools.physio.model.orthogonalise = 'none';
        
        % Physio regressors -----------------------------------------------
        
        if par.RETROICOR
            jobs{j}.spm.tools.physio.model.retroicor.yes.order.c = 3;
            jobs{j}.spm.tools.physio.model.retroicor.yes.order.r = 4;
            jobs{j}.spm.tools.physio.model.retroicor.yes.order.cr = 1;
        else
            jobs{j}.spm.tools.physio.model.retroicor.no = struct([]);
        end
        
        if par.RVT
            jobs{j}.spm.tools.physio.model.rvt.yes.delays = 0;
        else
            jobs{j}.spm.tools.physio.model.rvt.no = struct([]);
        end
        
        if par.HRV
            jobs{j}.spm.tools.physio.model.hrv.yes.delays = 0;
        else
            jobs{j}.spm.tools.physio.model.hrv.no = struct([]);
        end
        
        % Noise ROI model (PCA) ------------------------------------------
        
        if par.noiseROI
            
            fmri_files     = get_subdir_regex_files( dirFunc{subj}(run) , par.noiseROI_files_regex, p );
            noiseROI_files = get_subdir_regex_files( dirNoiseROI{subj}  , par.noiseROI_mask_regex, p );
            
            jobs{j}.spm.tools.physio.model.noise_rois.yes.fmri_files       = fmri_files; % requires 4D volume
            jobs{j}.spm.tools.physio.model.noise_rois.yes.roi_files        = cellstr(char(noiseROI_files));
            jobs{j}.spm.tools.physio.model.noise_rois.yes.force_coregister = 'No';
            jobs{j}.spm.tools.physio.model.noise_rois.yes.thresholds       = par.noiseROI_thresholds;
            jobs{j}.spm.tools.physio.model.noise_rois.yes.n_voxel_crop     = par.noiseROI_n_voxel_crop;
            jobs{j}.spm.tools.physio.model.noise_rois.yes.n_components     = par.noiseROI_n_components;
            
        else
            
            jobs{j}.spm.tools.physio.model.noise_rois.no = struct([]);
            
        end
        
        % Realignment parameters ------------------------------------------
        
        if par.rp
            
            rp = get_subdir_regex_files( dirFunc{subj}(run) , par.rp_regex , 1 );
            
            jobs{j}.spm.tools.physio.model.movement.yes.file_realignment_parameters = rp;
            jobs{j}.spm.tools.physio.model.movement.yes.order                       = par.rp_order;
            jobs{j}.spm.tools.physio.model.movement.yes.censoring_method            = par.rp_method;
            jobs{j}.spm.tools.physio.model.movement.yes.censoring_threshold         = par.rp_threshold;
            
        end
        
        % Other regressors ------------------------------------------------
        
        if ~isempty(par.other_regressor_regex)
            other_reg = get_subdir_regex_files( dirPhysio{subj}{run} , par.other_regressor_regex , 1 );
            jobs{j}.spm.tools.physio.model.other.yes.input_multiple_regressors = other_reg;
        else
            jobs{j}.spm.tools.physio.model.other.no = struct([]);
        end
        jobs{j}.spm.tools.physio.verbose.level = par.print_figures;
        jobs{j}.spm.tools.physio.verbose.fig_output_file = '';
        jobs{j}.spm.tools.physio.verbose.use_tabs = false;
        
    end
    
end

%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


end % function
