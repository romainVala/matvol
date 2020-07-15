function jobs = job_physio_tapas( par )
% JOB_PHYSIO_TAPAS - SPM:tools:physio
%
% SYNTAX
%       JOB_PHYSIO_TAPAS( par );
%
% "par" is a structure, where each field is described bellow :
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% ALWAYS MANDATORY
%----------------------------------------------------------------------------------------------------------------------------------------------------
%    .TR       (seconds)
%    .nSlice   (int    )
%    .volume   (cellstr) multi-level cell, such as par.volume{iSubj}{iRun} = '/path/to/volume.nii'
%                                               the volume will be used to fetch Nscans (number of time points == TRs)
%    .outdir   (cellstr) multi-level cell, such as par.outdir{iSubj}{iRun} = '/path/to/outdir/'
%    .physio   (0 or 1)  RETROICOR, HRV, RVT
%    .noiseROI (0 or 1)  aCompCor (PCA on WM and CSF)
%    .rp       (0 or 1)  add first/second derivative of RP, Framewise Displacement (FD) thresholding
%
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% Physio
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
% Mandatory
%
%    .physio_Info (cellstr) multi-level cell, such as par.physio_Info{iSubj}{iRun} = '/path/to/*_Info.log'
%    .physio_PULS (cellstr) multi-level cell, such as par.physio_PULS{iSubj}{iRun} = '/path/to/*_PULS.log'
%    .physio_RESP (cellstr) multi-level cell, such as par.physio_RESP{iSubj}{iRun} = '/path/to/*_RESP.log'
%
% Optional
%
%    .physio_RETROICOR (1 or 0)
%    .physio_HRV       (1 or 0)
%    .physio_RVT       (1 or 0)
%    .physio_logfiles_vendor  = 'Siemens_Tics'; % Siemens CMRR multiband sequence, only this one is coded yet
%    .par.logfiles_align_scan = 'last';         % 'last' / 'first'
%    .par.slice_to_realign    = 'middle';       % 'first' / 'middle' / 'last' / sliceNumber (integer)
%
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% noiseROI
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
% Mandatory
%
%    .noiseROI_mask   (cellstr) multi-level cell, such as par.noiseROI_mask  {iSubj}{iMask} = '/path/to/mask.nii'
%                               you can enter severa masks, such as WM and CSF
%                               for faster job computation, masks should already be Coregister:Estimate&Reslice to the functionnal volume
%    .noiseROI_volume (cellstr) multi-level cell, such as par.noiseROI_volume{iSubj}{iRun } = '/path/to/volume.nii'
%                               use 4D volumes (.nii)
%                               functionnal volume, should be in the final space (closest to the model) but **not smoothed**
%
% Optional
%
%    .noiseROI_thresholds   = [0.95 0.95];     % keep voxels with tissu probabilty >= 95%
%    .noiseROI_n_voxel_crop = [2 1];           % crop n voxels in each direction, to avoid partial volume
%    .noiseROI_n_components = 10;              % keep n PCA componenets
%
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% Realignment Parameters
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
% Mandatory
%
%    .rp_file (cellstr) multi-level cell, such as par.rp_file{iSubj}{iRun} = '/path/to/rp*.txt'
%
% Optional
%
%    .rp_order     = 24;   % can be 6, 12, 24
%                          % 6 = just add rp, 12 = also adds first order derivatives, 24 = also adds first + second order derivatives
%    .rp_method    = 'FD'; % 'MAXVAL' / 'FD' / 'DVARS'
%    .rp_threshold = 0.5;  % Threshold above which a stick regressor is created for corresponding volume of exceeding value
%


if nargin==0, help(mfilename('fullpath')); return; end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

%----------------------------------------------------------------------------------------------------------------------------------------------------
% ALWAYS MANDATORY
%----------------------------------------------------------------------------------------------------------------------------------------------------

defpar.physio   = 0;
defpar.noiseROI = 0;
defpar.rp       = 0;


%----------------------------------------------------------------------------------------------------------------------------------------------------
% Physio
%----------------------------------------------------------------------------------------------------------------------------------------------------

defpar.physio_RETROICOR        = 1;
defpar.physio_HRV              = 1;
defpar.physio_RVT              = 1;
defpar.physio_logfiles_vendor  = 'Siemens_Tics'; % Siemens CMRR multiband sequence, only this one is coded yet
defpar.logfiles_align_scan = 'last';         % 'last' / 'first'
% Determines which scan shall be aligned to which part of the logfile.
% Typically, aligning the last scan to the end of the logfile is beneficial, since start of logfile and scans might be shifted due to pre-scans;
defpar.slice_to_realign    = 'middle';       % 'first' / 'middle' / 'last' / sliceNumber (integer)
% Slice to which regressors are temporally aligned. Typically the slice where your most important activation is expected.


%----------------------------------------------------------------------------------------------------------------------------------------------------
% noiseROI
%----------------------------------------------------------------------------------------------------------------------------------------------------

defpar.noiseROI_thresholds   = [0.95 0.95];     % keep voxels with tissu probabilty >= 95%
defpar.noiseROI_n_voxel_crop = [2 1];           % crop n voxels in each direction, to avoid partial volume
defpar.noiseROI_n_components = 10;              % keep n PCA componenets


%----------------------------------------------------------------------------------------------------------------------------------------------------
% Realignment Parameters
%----------------------------------------------------------------------------------------------------------------------------------------------------

defpar.rp_order     = 24;   % can be 6, 12, 24
% 6 = just add rp, 12 = also adds first order derivatives, 24 = also adds first + second order derivatives
defpar.rp_method    = 'FD'; % 'MAXVAL' / 'FD' / 'DVARS'
defpar.rp_threshold = 0.5;  % Threshold above which a stick regressor is created for corresponding volume of exceeding value


%----------------------------------------------------------------------------------------------------------------------------------------------------
% Other
%----------------------------------------------------------------------------------------------------------------------------------------------------
defpar.print_figures         = 1; % 0 , 1 , 2 , 3

% classic matvol
defpar.run      = 1;
defpar.display  = 0;
defpar.redo     = 0;

% cluster
defpar.jobname  = 'spm_physio';
defpar.walltime = '04:00:00';
defpar.mem      = '4G';
defpar.sge      = 0;

par = complet_struct(par,defpar);


%% Some checks

nSubj = nan(4,1);

if par.physio
    nSubj_physio_Info = length(par.physio_Info);
    nSubj_physio_PULS = length(par.physio_PULS);
    nSubj_physio_RESP = length(par.physio_RESP);
    assert( nSubj_physio_Info==nSubj_physio_PULS  &&  nSubj_physio_PULS==nSubj_physio_RESP, 'pb with physio Info/PULS/RESP' )
    nSubj(1) = nSubj_physio_Info;
end

if par.noiseROI
    nSubj_noiseROI_mask   = length(par.noiseROI_mask  );
    nSubj_noiseROI_volume = length(par.noiseROI_volume);
    assert( nSubj_noiseROI_mask==nSubj_noiseROI_volume , 'pb with noiseROI mask/volume' )
    nSubj(2) = nSubj_noiseROI_mask;
end

if par.rp
    nSubj(3) = length(par.rp_file);
end

nSubj(4) = length(par.outdir);


nSubj = nSubj( ~isnan(nSubj) );
assert( ~isempty(nSubj) , 'at least one method is required : physio/noiseROI/rp')
assert( range(nSubj)==0, 'different number of subjects on physio/noiseROI/rp')
nSubj = nSubj(1);

if ~par.physio
    par.physio_RETROICOR = 0;
    par.physio_HRV       = 0;
    par.physio_RVT       = 0;
end


%% Prepare job

j = 0; % counter

p.verbose = 0;

skip = [];


for iSubj = 1:nSubj
    
    nRun = length(par.outdir{iSubj});
    
    for iRun = 1:nRun
        
        j = j + 1; % counter
        
        % Save dir --------------------------------------------------------
        
        jobs{j}.spm.tools.physio.save_dir = par.outdir{iSubj}(iRun); %#ok<*AGROW>
        
        outputfile = fullfile(par.outdir{iSubj}{iRun},'multiple_regressors.txt');
        if ~par.redo && exist(outputfile,'file')
            skip = [skip j];
            fprintf('[%s]: skiping iSubj %d because %s exist \n',mfilename,iSubj,outputfile);
            continue
        end
        
        if par.physio
            
            % Physio files ----------------------------------------------------
            
            if ~strcmp(par.logfiles_vendor,'Siemens_Tics')
                error('[%s] only "%s" is coded yet', mfilename, 'Siemens_Tics' )
            end
            
            jobs{j}.spm.tools.physio.log_files.vendor      = par.logfiles_vendor;
            jobs{j}.spm.tools.physio.log_files.cardiac     = par.physio_PULSE{iSubj}(iRun);
            jobs{j}.spm.tools.physio.log_files.respiration = par.physio_RESP {iSubj}(iRun);
            jobs{j}.spm.tools.physio.log_files.scan_timing = par.physio_Info {iSubj}(iRun);
            jobs{j}.spm.tools.physio.log_files.sampling_interval          = [];
            jobs{j}.spm.tools.physio.log_files.relative_start_acquisition = 0;
            jobs{j}.spm.tools.physio.log_files.align_scan                 = 'last';
            
        else
            
            jobs{j}.spm.tools.physio.log_files.cardiac     = {''};
            jobs{j}.spm.tools.physio.log_files.respiration = {''};
            jobs{j}.spm.tools.physio.log_files.scan_timing = {''};
            
        end
        
        % Volume info -----------------------------------------------------
        
        % from header extracted by SPM
        V         = spm_vol_nifti(par.volume{iSubj}{iRun}); % Read volume header
        nTR = V.private.dat.dim(4);
        
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Nslices        = par.nSlice;
        jobs{j}.spm.tools.physio.scan_timing.sqpar.NslicesPerBeat = [];
        jobs{j}.spm.tools.physio.scan_timing.sqpar.TR             = par.TR;
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Ndummies       = 0; % no dummy scan with Siemmens scanner
        jobs{j}.spm.tools.physio.scan_timing.sqpar.Nscans         = nTR;
        switch par.slice_to_realign
            case 'first'
                onset_slice = 1;
            case 'middle'
                onset_slice = round(par.nSlice/2);
            case 'last'
                onset_slice = par.nSlice;
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
        
        if par.physio_RETROICOR
            jobs{j}.spm.tools.physio.model.retroicor.yes.order.c  = 3;
            jobs{j}.spm.tools.physio.model.retroicor.yes.order.r  = 4;
            jobs{j}.spm.tools.physio.model.retroicor.yes.order.cr = 1;
        else
            jobs{j}.spm.tools.physio.model.retroicor.no = struct([]);
        end
        
        if par.physio_RVT
            jobs{j}.spm.tools.physio.model.rvt.yes.delays = 0;
        else
            jobs{j}.spm.tools.physio.model.rvt.no = struct([]);
        end
        
        if par.physio_HRV
            jobs{j}.spm.tools.physio.model.hrv.yes.delays = 0;
        else
            jobs{j}.spm.tools.physio.model.hrv.no = struct([]);
        end
        
        % Noise ROI model (PCA) ------------------------------------------
        
        if par.noiseROI
            
            jobs{j}.spm.tools.physio.model.noise_rois.yes.fmri_files       = par.noiseROI_volume{iSubj}(iRun); % requires 4D volume
            jobs{j}.spm.tools.physio.model.noise_rois.yes.roi_files        = par.noiseROI_mask  {iSubj};       % all masks
            jobs{j}.spm.tools.physio.model.noise_rois.yes.force_coregister = 'No';
            jobs{j}.spm.tools.physio.model.noise_rois.yes.thresholds       = par.noiseROI_thresholds;
            jobs{j}.spm.tools.physio.model.noise_rois.yes.n_voxel_crop     = par.noiseROI_n_voxel_crop;
            jobs{j}.spm.tools.physio.model.noise_rois.yes.n_components     = par.noiseROI_n_components;
            
        else
            
            jobs{j}.spm.tools.physio.model.noise_rois.no = struct([]);
            
        end
        
        % Realignment parameters ------------------------------------------
        
        if par.rp
            
            jobs{j}.spm.tools.physio.model.movement.yes.file_realignment_parameters = par.rp_file{iSubj}(iRun);
            jobs{j}.spm.tools.physio.model.movement.yes.order                       = par.rp_order;
            jobs{j}.spm.tools.physio.model.movement.yes.censoring_method            = par.rp_method;
            jobs{j}.spm.tools.physio.model.movement.yes.censoring_threshold         = par.rp_threshold;
            
        end
        
        % Other -----------------------------------------------------------
        
        jobs{j}.spm.tools.physio.model.other.no = struct([]);
        jobs{j}.spm.tools.physio.verbose.level = par.print_figures;
        jobs{j}.spm.tools.physio.verbose.fig_output_file = '';
        jobs{j}.spm.tools.physio.verbose.use_tabs = false;
        
    end
    
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


end % function
