function TS_struct = job_extract_timeseries(par)
%job_extract_timeseries
% 1. Please check atlas list bellow (from CAT12)
% 2. If you already runned this function but you want to add another atlas,
%    no worries, unecessary steps will be skipped
%
% WORKFLOW
%   1. clean volume using confounds : SPM GLM (specify, estimate, convert residuals from 3D to 4D)
%   2. bandpass cleaned 4D volume using FFT
%   optional: write ALFF and fALFF from FFT outputs
%   3. copy atlas from CAT12 in local directory
%   4. reslice atlas to functionnal (same grid : same matrix & same resolution)
%   5. extract timeseries using labels in the atlas ( timeseries = 1st eigen variate from PCA using SVD )
%   6. write timeseries
%
% SYNTAX
%   TS = job_extract_timeseries(par)
%
% AFTER
%   whole timeseries connectivity matrix : job_timeseries_to_connectivity_matrix + plot_resting_state_connectivity_matrix
%   whole timeseries seedbased connectivity : job_timeseries_to_connectivity_seedbased_pearson_zfisher
%
% "par" is a structure, where each field is described here :
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% MANDATORY
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
%    .volume   (cellstr/@volume) such as par.volume{iVol} = '/path/to/volume.nii'
%                                OR
%                                a @volume object from matvol
%
%    .confound (cellstr/@rp)     such as par.confound{iVol} = '/path/to/rp*.txt'
%                                OR
%                                a @rp object from matvol
%
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% also MANDATORY, at least one
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
%    .roi_type.atlas_cat12  (char/cellstr)  available atlas in CAT12 are : 
%                                  * aal3, anatomy3, cobra, hammers, ibsr, julichbrain, lpba40, mori, neuromorphometrics, thalamus
%                                  * Schaefer2018_100Parcels_17Networks_order
%                                  * Schaefer2018_200Parcels_17Networks_order
%                                  * Schaefer2018_400Parcels_17Networks_order
%                                  * Schaefer2018_600Parcels_17Networks_order
%                                  check them in : fullfile(spm('dir'), 'toolbox', 'cat12', 'templates_MNI152NLin2009cAsym')
%                                  it can be a char    such as 'aal3'
%                                  OR
%                                  it can be a cellstr such as {'aal3', 'ibsr'}
%
%
%    .roi_type.mask_global  (cellstr)  such as :
%                                 par.roi_type.mask_global = {
%                                     % path                  abbrev     description
%                                     '/path/to/mask1.nii',  'mask_1',  'my mask region 1'
%                                     '/path/to/mask2.nii',  'mask_2',  'my mask region 2'
%                                     };
%                                 theses masks ar non-volume (subject) specific, each mask from the list will be used on all volumes
%
%
%    (.roi_type.mask_specific !!! not coded yet !!!)
%
%
%    .roi_type.sphere_global  (cell), such as :
%                                 par.roi_type.sphere = {
%                                     % [x y z]mm       radius(mm)   abbrev      fullname
%                                     [ +10 +20 +30 ],  3,          'sphere_1'  'my sphere region 1'
%                                     [ -50 -20 +30 ],  6,          'sphere_2'  'my sphere region 2'
%                                     };
%
%
%    (.roi_type.atlas_freesurfer !!! not coded yet !!!)
%
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% Mandatory ? it depends...
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
%    .outname  (char)              if set, this paramter will override the automatic outname generation
%                                  this CAN be mandatory if the automatic outname is too long and so the .mat file cannot be written
%                                  automatic outname is the contanetation of all input roi names : if you have many masks, this can be very long
%
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% Optional
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
%    .mask     (cellstr/@volume)   such as par.mask{iVol} = '/path/to/mask.nii'
%                                  OR
%                                  a @volume object from matvol
%
%    .mask_threshold = (double)    some value, like 0.8
%
%    .bandpass = [fbot ftop]       in Hz
%
%    .write_ALFF (bool)            Apmlitude of Low Frequency Fluctuations
%                                  is the average square root of Fourier coefficents inside the low frequency band (defined by .bandpass)
%
%    .write_fALFF (bool)           fraction of Apmlitude of Low Frequency Fluctuations
%                                  is the sum of Fourier coefficients inside the low frequency band (defined by .bandpass) devided the sum of the remaining frequencies
%
% See also job_timeseries_to_connectivity_matrix plot_resting_state_connectivity_matrix job_timeseries_to_connectivity_network job_timeseries_to_connectivity_seedbased_pearson_zfisher

if nargin==0, help(mfilename('fullpath')); return; end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

%----------------------------------------------------------------------------------------------------------------------------------------------------
% ALWAYS MANDATORY
%----------------------------------------------------------------------------------------------------------------------------------------------------
assert(isfield(par,'volume'), 'par.volume is mandatory, check help')
assert(isfield(par,'confound'), 'par.confound is mandatory, check help')

%----------------------------------------------------------------------------------------------------------------------------------------------------
% Optional
%----------------------------------------------------------------------------------------------------------------------------------------------------
defpar.mask_threshold = 0.8;
defpar.bandpass       = [0.01 0.1]; % Hz
defpar.write_ALFF     = true;
defpar.write_fALFF    = true;

defpar.subdir         = 'rsfc';
defpar.glmdir         = 'glm';
defpar.clean4D_name   = 'clean.nii';

%----------------------------------------------------------------------------------------------------------------------------------------------------
% Other
%----------------------------------------------------------------------------------------------------------------------------------------------------

% classic matvol
defpar.run          = 1;
defpar.redo         = 0;
defpar.auto_add_obj = 1;

% cluster
defpar.sge      = 0;
defpar.mem      = '4G';
defpar.walltime = '04:00:00';
defpar.jobname  = mfilename;

par = complet_struct(par,defpar);


%% Check input volumes, confounds, (and masks)

nVol = nan(4,1);

obj = 0;
if isa(par.volume,'volume')
    obj = 1;
    volumeArray = par.volume;
    par.volume = par.volume.getPath();
end
nVol(1) = numel(par.volume);

if isa(par.confound,'rp')
    par.confound = par.confound.getPath();
end
nVol(2) = numel(par.confound);

use_mask_glm = 0;
if isfield(par, 'mask')
    use_mask_glm = 1;
    if isa(par.mask,'volume')
        par.mask = par.mask.getPath();
    end
    nVol(3) = numel(par.mask);
end

nVol = nVol( ~isnan(nVol) );
assert( all(nVol(1)==nVol), 'different number of subjects on volume/confonnd/mask')
nVol = nVol(1);


%% Check input ROI

% check .roi_type field
assert(isfield(par, 'roi_type'), 'roi_type must be field in the parameters. Check hehp')

% check .roi_type sub-fields
allowed_roi_type = {'atlas_cat12', 'mask_global', 'sphere_global'};
msg_allowed_roi_type = sprintf(repmat('%s, ', [1 length(allowed_roi_type)]), allowed_roi_type{:});
input_roi_type = fieldnames(par.roi_type);
for iType = 1 : length(input_roi_type)
    assert( any(strcmp(input_roi_type{iType},allowed_roi_type)) , '''%s'' is not allowed, allowed list = {%s}', input_roi_type{iType}, msg_allowed_roi_type )
end

% initialize all flags
use_atlas         = 0;
use_atlas_cat12   = 0;
use_mask          = 0;
use_mask_global   = 0;
use_sphere        = 0;
use_sphere_global = 0;

outname1 = '';
outname2 = '';

% check all types
if isfield(par.roi_type, 'atlas_cat12')
    use_atlas        = 1;
    use_atlas_cat12  = 1;
    atlas_cat12_dir  = fullfile(spm('dir'), 'toolbox', 'cat12', 'templates_MNI152NLin2009cAsym');
    atlas_cat12_list = cellstr(par.roi_type.atlas_cat12);
    outname1 = sprintf('%s%s__', outname1, strjoin(atlas_cat12_list,'_'));
    outname2 = sprintf('%s%s__', outname2, strjoin(atlas_cat12_list,'_'));
end
if isfield(par.roi_type, 'mask_global')
    use_mask         = 1;
    use_mask_global  = 1;
    assert( iscell(par.roi_type.mask_global) && ~isempty(par.roi_type.mask_global) , 'par.roi_type.mask_global must be a non-empty cell' )
    mask_global_list = par.roi_type.mask_global;
    outname1 = sprintf('%s%s__', outname1, strjoin(mask_global_list(:,2),'_')); % column 2 is abbreviation
    gmsk_abbrev = char(mask_global_list(:,2));
    gmsk_letter = gmsk_abbrev(:,1);
    outname2 = sprintf('%s%s__', outname2, gmsk_letter(:)');
end
if isfield(par.roi_type, 'sphere_global')
    use_sphere         = 1;
    use_sphere_global  = 1;
    assert( iscell(par.roi_type.sphere_global) && ~isempty(par.roi_type.sphere_global) , 'par.roi_type.sphere_global must be a non-empty cell' )
    sphere_global_list = par.roi_type.sphere_global;
    outname1 = sprintf('%s%s__', outname1, strjoin(sphere_global_list(:,3),'_')); % column 3 is abbreviation
    gsph_abbrev = char(sphere_global_list(:,3));
    gsph_letter = gsph_abbrev(:,1);
    outname2 = sprintf('%s%s__', outname2, gsph_letter(:)');
end
outname1 = outname1(1:end-2); % delete last 2 underscore
outname2 = outname2(1:end-2); % delete last 2 underscore


%% ------------------------------------------------------------------------
%% main
%% ------------------------------------------------------------------------

TS_struct = struct;
job_sge   = {};

for iVol = 1:nVol
    %% Preparations
    
    % prepare output dir path
    volume_path = par.volume(iVol);
    fprintf('[%s]: volume %d/%d : %s \n', mfilename, iVol, nVol, char(volume_path))
    outdir_path         = fullfile(get_parent_path(char(volume_path)), par.subdir);
    glmdir_path         = fullfile(outdir_path, par.glmdir);
    cleaned_volume_path = fullfile(outdir_path, par.clean4D_name);
    bp_volume_path      = fullfile(outdir_path, ['bp_' par.clean4D_name]);
    
    % output_struct
    TS_struct(iVol).volume     = char(par.volume  (iVol));
    TS_struct(iVol).confound   = char(par.confound(iVol));
    TS_struct(iVol).outdir     = outdir_path;
    TS_struct(iVol).glmdir     = glmdir_path;
    TS_struct(iVol).clean      = cleaned_volume_path;
    TS_struct(iVol).bp_clean   = bp_volume_path;
    TS_struct(iVol).bandpass   = par.bandpass;
    TS_struct(iVol).roi_type   = par.roi_type;
    TS_struct(iVol).use_obj    = obj;
    if TS_struct(iVol).use_obj
        TS_struct(iVol).obj.volume = volumeArray(iVol);
    end
    
    % outname
    if isfield(par, 'outname') % used defined outname
        outname = par.outname; timeseries_path = fullfile(outdir_path,sprintf('timeseries__%s.mat', outname));
        if length(timeseries_path) > 255 || length(outname) > 63
            error('output filename will too long... reduce size of par.outname')
        end
    else % automatic outname
        outname = outname1; timeseries_path = fullfile(outdir_path,sprintf('timeseries__%s.mat', outname));
        if length(timeseries_path) > 255 || length(outname) > 63
            outname = outname2; timeseries_path = fullfile(outdir_path,sprintf('timeseries__%s.mat', outname));
            assert(length(timeseries_path) <= 255, 'automatic output filename will be too long... you need to set it manally with par.outname = ''my_rsfc_name'' ')
        end
    end
    TS_struct(iVol).outname         = outname;
    TS_struct(iVol).timeseries_path = timeseries_path;
    
    % skip if final output exists
    if exist(timeseries_path, 'file') && ~par.redo
        fprintf('[%s]:          timeseries extraction done : %s \n', mfilename, timeseries_path)
        continue
    end
    
    
    %% Prepare jobs for the cluster, if needed
    
    if par.sge
        cfg = par; % copy
        cfg.volume = par.volume(iVol);
        cfg.confound = par.confound(iVol);
        if isfield(par,'mask'), cfg.mask = par.mask(iVol); end
        cfg.sge = 0;
        cfg.run = 1;
        code = gencode(cfg, 'par')';
        code{end+1} = sprintf('%s(par)', mfilename); %#ok<AGROW> 
        code{end+1} = ''; %#ok<AGROW> 
        code = strjoin(code, sprintf('\n')); %#ok<SPRINTFN> 
        job_sge{end+1} = code; %#ok<AGROW> 
        continue
    end
    
    
    %% Clean volume and filter it (plus ALFF, fALFF)
    
    if ~exist(cleaned_volume_path, 'file') || par.redo
        
        if par.redo
            do_delete(outdir_path,0)
        end
        
        % fetch TR and number of timepoints (nTR)
        fprintf('[%s]:      fetch TR and number of timepoints \n', mfilename)
        [TR, nTR, scans] = load_4D_volume_info(volume_path);
        
        %------------------------------------------------------------------
        % clean input volume from confounds
        %------------------------------------------------------------------
        fprintf('[%s]:      cleaning volume from confounds \n', mfilename)
        
        clear matlabbatch
        
        matlabbatch{1}.spm.stats.fmri_spec.dir            = {glmdir_path}; %%%
        matlabbatch{1}.spm.stats.fmri_spec.timing.units   = 'secs';
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT      = TR; %%%
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t  = 16;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
        matlabbatch{1}.spm.stats.fmri_spec.sess.scans     = scans; %%%
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond      = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.multi     = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess.regress   = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = par.confound(iVol); %%%%
        matlabbatch{1}.spm.stats.fmri_spec.sess.hpf       = 128;
        matlabbatch{1}.spm.stats.fmri_spec.fact             = struct('name', {}, 'levels', {});
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        matlabbatch{1}.spm.stats.fmri_spec.volt             = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global           = 'None';
        matlabbatch{1}.spm.stats.fmri_spec.mthresh  = par.mask_threshold; %%%
        if use_mask_glm
            matlabbatch{1}.spm.stats.fmri_spec.mask = par.mask(iVol); %%%
        else
            matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
        end
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
        matlabbatch{2}.spm.stats.fmri_est.spmmat(1)        = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
        matlabbatch{2}.spm.stats.fmri_est.write_residuals  = 1;
        matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
        matlabbatch{3}.spm.util.cat.vols(1) = cfg_dep('Model estimation: Residual Images', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','res'));
        matlabbatch{3}.spm.util.cat.name    = par.clean4D_name;
        matlabbatch{3}.spm.util.cat.dtype   = 0;
        matlabbatch{3}.spm.util.cat.RT      = TR; %%%%
    
        spm_jobman('run', matlabbatch)
        
        symlink(fullfile(glmdir_path, par.clean4D_name), cleaned_volume_path                              , par.redo);
        symlink(fullfile(glmdir_path, 'mask.nii'      ), fullfile(outdir_path, ['mask_' par.clean4D_name]), par.redo);
        
    else
        
        [TR, nTR, scans] = load_4D_volume_info(volume_path);
        
    end
    
    %----------------------------------------------------------------------
    % get cleaned volume and bandpass it using FFT
    %----------------------------------------------------------------------
    % here is also a good occasion to compute ALFF and fALFF since they use Fourier corefficients from the FFT
    
    if ~exist(bp_volume_path, 'file') || par.redo
    
        fprintf('[%s]:      bandpass filtering using FFT \n', mfilename)
        
        % load volume
        cleaned_volume_header = spm_vol      (cleaned_volume_path              );
        cleaned_volume_4D     = spm_read_vols(cleaned_volume_header            );   % [x y z t]
        
        % load mask
        mask_header           = spm_vol      (fullfile(glmdir_path, 'mask.nii'));
        [mask_3D, XYZmm]      = spm_read_vols(mask_header                      );   % [x y z]
        mask_3D               = logical(mask_3D);
        
        % convert to 2D array == timeseries [ mask(nVoxel) nTR ]
        mask_1D                       = mask_3D(:);                                 % [x*y*z 1]
        size_volume_4D                = size(cleaned_volume_4D);
        nVoxel                        = prod(size_volume_4D(1:3));
        size_volume_2D                = [nVoxel nTR];
        cleaned_volume_2D             = reshape(cleaned_volume_4D, size_volume_2D); % [     x*y*z  t]
        cleaned_volume_2D(~mask_1D,:) = [];                                         % [mask(x*y*z) t];
        
        % bandpass using FFT
        FFT = fft(cleaned_volume_2D, [], 2); % [mask(x*y*z) t];
        mag = abs  (FFT);                    % [mask(x*y*z) t];
        pha = angle(FFT);                    % [mask(x*y*z) t];
        clear cleaned_volume_4D cleaned_volume_2D FFT
        
        % generate freq vector
        if mod(nTR,2) == 1
            freq_left = (1/TR) * (0 : (nTR/2)) / nTR;
            freq = [freq_left fliplr(freq_left)];
            freq(end) = [];
        else
            freq_left = (1/TR) * (0 : (nTR/2-1)) / nTR;
            freq = [freq_left fliplr(freq_left)];
        end
        
        % generate frequency "mask"
        bp_freq = true(size(freq));
        bp_freq(freq < par.bandpass(1)) = false;
        bp_freq(freq > par.bandpass(2)) = false;
        
        % now we bandpass
        bp = real(ifft( mag.*bp_freq .* exp(1i*pha), [], 2));              % [mask(x*y*z) t];
        clear pha
        
        % ALFF
        if par.write_ALFF
            fprintf('[%s]:      writing  ALFF \n', mfilename)
            
            ALFF = mean(sqrt(mag(:,bp_freq)),2);                           % [mask(x*y*z) 1];
            
            % unmask : [mask(x*y*z) 1 ] ---> [x y z]
            ALFF_2D            = NaN(nVoxel,1);                            % [x*y*z 1]
            ALFF_2D(mask_1D,:) = ALFF;
            ALFF_3D            = reshape(ALFF_2D, size_volume_4D(1:3));    % [x y z]
            
            % write volume
            V_ALFF = struct;
            V_ALFF.fname   = fullfile(outdir_path, ['ALFF_' par.clean4D_name]);
            V_ALFF.dim     = cleaned_volume_header(1).dim;
            V_ALFF.dt      = cleaned_volume_header(1).dt;
            V_ALFF.mat     = cleaned_volume_header(1).mat;
            V_ALFF.pinfo   = cleaned_volume_header(1).pinfo;
            V_ALFF.descrip = sprintf('ALFF [%g %g]', par.bandpass(1), par.bandpass(2));
            spm_write_vol(V_ALFF,ALFF_3D);
            clear ALFF ALFF_2D ALFF_3D
        end
        
        % fALFF
        if par.write_fALFF
            fprintf('[%s]:      writing fALFF \n', mfilename)
            
            fALFF = sum(mag(:,bp_freq),2) ./ sum(mag(:,~bp_freq),2);       % [mask(x*y*z) 1];
            
            % unmask : [mask(x*y*z) 1 ] ---> [x y z]
            fALFF_2D            = NaN(nVoxel,1);                           % [x*y*z 1]
            fALFF_2D(mask_1D,:) = fALFF;
            fALFF_3D            = reshape(fALFF_2D, size_volume_4D(1:3));  % [x y z]
            
            % write volume
            V_fALFF = struct;
            V_fALFF.fname   = fullfile(outdir_path, ['fALFF_' par.clean4D_name]);
            V_fALFF.dim     = cleaned_volume_header(1).dim;
            V_fALFF.dt      = cleaned_volume_header(1).dt;
            V_fALFF.mat     = cleaned_volume_header(1).mat;
            V_fALFF.pinfo   = cleaned_volume_header(1).pinfo;
            V_fALFF.descrip = sprintf('fALFF [%g %g]', par.bandpass(1), par.bandpass(2));
            spm_write_vol(V_fALFF,fALFF_3D);
            clear fALFF fALFF_2D fALFF_3D
        end
        
        clear mag pha
        
        % write bandpass volume
        fprintf('[%s]:      writing bandpassed volume \n', mfilename)
        bp_2D = NaN(size_volume_2D); % [x*y*z t]
        bp_2D(mask_1D,:) = bp;
        bp_4D = reshape(bp_2D, size_volume_4D); % [x y z t]
        bp_header = cleaned_volume_header(1);
        bp_nifti = cleaned_volume_header(1).private;
        bp_nifti.dat.fname = bp_volume_path;
        bp_nifti.descrip = sprintf('bandpass [%g %g]', par.bandpass(1), par.bandpass(2));
        create(bp_nifti)
        bp_nifti.dat(:,:,:,:) = bp_4D;
        clear bp bp_4D
        
    else
        
        fprintf('[%s]:      loading filtered (bandpass) volume \n', mfilename)
        
        bp_header    = spm_vol      (bp_volume_path);
        [bp_4D,XYZmm]= spm_read_vols(bp_header     );                      % [x y z t]
        
        size_volume_4D = size(bp_4D);
        nVoxel         = prod(size_volume_4D(1:3));
        size_volume_2D = [nVoxel nTR];
        
        bp_2D = reshape(bp_4D, size_volume_2D);                            % [ x*y*z  t]
        clear bp_4D
        
    end
    
    % final shape : [nTR x*y*z]
    % each column is a voxel timeseries, for later principal component extraction
    bp_2D = bp_2D';
    assert(size(bp_2D,1)==nTR)
    assert(size(bp_2D,2)==nVoxel)
    
    
    %% Loop over all ROI sources
    
    % setup container
    timeseries = zeros(nTR,0);
    ts_counter = 0;
    ts_table_columns = {'id', 'id0', 'abbreviation', 'description', 'nvoxel', 'type', 'source'};
    ts_table = array2table(zeros(0,length(ts_table_columns)));
    ts_table.Properties.VariableNames = ts_table_columns;
    
    
    %----------------------------------------------------------------------
    % loop over cat12 atlases
    %----------------------------------------------------------------------
    
    if use_atlas
        
        if use_atlas_cat12
            
            for atlas_cat12_idx = 1 : length(atlas_cat12_list)
                
                atlas_cat12_name = atlas_cat12_list{atlas_cat12_idx};
                
                %----------------------------------------------------------
                % copy atlas and reslice it at functionnal resolution
                %----------------------------------------------------------
                
                % copy
                if ~exist(fullfile(outdir_path, [atlas_cat12_name '.nii']), 'file') || par.redo
                    fprintf('[%s]:          copy atlas files : %s \n', mfilename, atlas_cat12_name)
                    copyfile(fullfile(atlas_cat12_dir, [atlas_cat12_name '.nii']), fullfile(outdir_path, [atlas_cat12_name '.nii']))
                    copyfile(fullfile(atlas_cat12_dir, [atlas_cat12_name '.csv']), fullfile(outdir_path, [atlas_cat12_name '.csv']))
                    copyfile(fullfile(atlas_cat12_dir, [atlas_cat12_name '.txt']), fullfile(outdir_path, [atlas_cat12_name '.txt']))
                end
                
                copy_atlas_cat12_path = fullfile(outdir_path, [    atlas_cat12_name '.nii']);
                resliced_atlas_path   = fullfile(outdir_path, ['r' atlas_cat12_name '.nii']);
                
                % reslice ?
                if spm_check_orientations([bp_header(1), spm_vol(copy_atlas_cat12_path)], false)
                    symlink(copy_atlas_cat12_path, resliced_atlas_path, par.redo)
                else
                    if ~exist(resliced_atlas_path, 'file') || par.redo
                        fprintf('[%s]:          reslice atlas to functional resolution : %s \n', mfilename, atlas_cat12_name)
                        
                        clear matlabbatch
                        matlabbatch{1}.spm.spatial.coreg.write.ref             = volume_path;
                        matlabbatch{1}.spm.spatial.coreg.write.source          = {fullfile(outdir_path, [atlas_cat12_name '.nii'])};
                        matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 0; % nearest interpolation, to avoid voxel blending
                        matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap   = [0 0 0];
                        matlabbatch{1}.spm.spatial.coreg.write.roptions.mask   = 0;
                        matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';
                        spm_jobman('run', matlabbatch)
                    end
                end
                
                
                %----------------------------------------------------------
                % load atlas .nii and .csv
                %----------------------------------------------------------
                atlas_cat12_header = spm_vol      (fullfile(outdir_path, ['r' atlas_cat12_name '.nii']));
                atlas_cat12_3D     = spm_read_vols(atlas_cat12_header                                  );
                atlas_cat12_table  = readtable    (fullfile(outdir_path, [    atlas_cat12_name '.csv']));
                
                % we need to make sure that all lines in the csv file correspond to a value in the nifti
                % for exemple, aal3 misses a few values in the .nii compared to its .csv
                values_in_atlas_3D = unique(atlas_cat12_3D(:));
                [~,values_in_atlas_table,~] = intersect(atlas_cat12_table.ROIid,values_in_atlas_3D);
                atlas_cat12_table = atlas_cat12_table(values_in_atlas_table,:);
                
                atlas_cat12_nROI = size(atlas_cat12_table,1);
                
                %----------------------------------------------------------
                % extract timeseries in ROIs
                %----------------------------------------------------------
                for iROI = 1 : atlas_cat12_nROI
                    
                    % extract voxels in ROI from the bandpassed volume
                    mask_ROI_3D = atlas_cat12_3D == atlas_cat12_table.ROIid(iROI);
                    mask_ROI_1D = mask_ROI_3D(:);
                    masked_bp_2D = bp_2D(:,mask_ROI_1D);
                    masked_bp_2D(~isfinite(masked_bp_2D)) = 0; % infinite values can appear when the label in the mask does not perfectly overlap with input BOLD data
                    
                    % extract ROI timeseries
                    y = extract_first_eigenvariate(masked_bp_2D);
                    assert(~any(isnan(y)), 'extracted timeseries contains NaN: %s in %s', atlas_cat12_table.ROIabbr(iROI), atlas_cat12_header.fname)
                    
                    % append data
                    ts_counter = ts_counter + 1;
                    timeseries(:,ts_counter) = y;
                    newrow              = struct;
                    newrow.id           = ts_counter;
                    newrow.id0          = ts_counter-1;
                    newrow.abbreviation = atlas_cat12_table.ROIabbr(iROI);
                    newrow.description  = atlas_cat12_table.ROIname(iROI);
                    newrow.nvoxel       = size(masked_bp_2D,2);
                    newrow.type         = {'atlas'};
                    newrow.source       = {'cat12'};
                    ts_table   = [ts_table;struct2table(newrow)]; %#ok<AGROW> 
                    
                end % iROI
            
            end % atlas_cat12_idx
            
        end % use_atlas_cat12
        
    end % use_atlas
    
    
    %----------------------------------------------------------------------
    % loop over mask global
    %----------------------------------------------------------------------
    
    if use_mask
        
        if use_mask_global
            
            for mask_global_idx = 1 : size(mask_global_list,1)
                
                mask_global_path = mask_global_list{mask_global_idx, 1};
                
                %----------------------------------------------------------
                % copy global mask and reslice it at functionnal resolution
                %----------------------------------------------------------
                
                % copy
                mask_global_copy_path = spm_file(mask_global_path, 'Path', outdir_path);
                if ~exist(mask_global_copy_path, 'file') || par.redo
                    fprintf('[%s]:          copy mask_global files : %s \n', mfilename, mask_global_path)
                    copyfile(mask_global_path, mask_global_copy_path)
                end
                
                resliced_mask_global_path = spm_file(mask_global_copy_path, 'Prefix', 'r');
                
                % reslice ?
                if spm_check_orientations([bp_header(1), spm_vol(mask_global_copy_path)], false)
                    symlink(mask_global_copy_path, resliced_mask_global_path, par.redo)
                else
                    if ~exist(resliced_mask_global_path, 'file') || par.redo
                        fprintf('[%s]:          reslice mask global to functional resolution : %s \n', mfilename, mask_global_copy_path)
                        
                        clear matlabbatch
                        matlabbatch{1}.spm.spatial.coreg.write.ref             = volume_path;
                        matlabbatch{1}.spm.spatial.coreg.write.source          = {mask_global_copy_path};
                        matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 0; % nearest interpolation, to avoid voxel blending
                        matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap   = [0 0 0];
                        matlabbatch{1}.spm.spatial.coreg.write.roptions.mask   = 0;
                        matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';
                        spm_jobman('run', matlabbatch)
                    end
                end
                
                %----------------------------------------------------------
                % load mask global
                %----------------------------------------------------------
                mask_global_V = spm_vol      (resliced_mask_global_path);
                mask_global_Y = spm_read_vols(mask_global_V      );
                mask_global_Y(~isfinite(mask_global_Y)) = 0;
                mask_global_Y = logical(mask_global_Y);
                assert(sum(mask_global_Y(:))>0, 'after minimal cleaning, empty mask : %s', resliced_mask_global_path)
                
                
                %----------------------------------------------------------
                % extract timeserie
                %----------------------------------------------------------
                masked_bp_2D = bp_2D(:,mask_global_Y(:));
                masked_bp_2D(~isfinite(masked_bp_2D)) = 0; % infinite values can appear when the label in the mask does not perfectly overlap with input BOLD data
                
                % extract ROI timeseries
                y = extract_first_eigenvariate(masked_bp_2D);
                assert(~any(isnan(y)), 'extracted timeseries contains NaN: %s', resliced_mask_global_path)
                
                % append data
                ts_counter = ts_counter + 1;
                timeseries(:,ts_counter) = y;
                newrow              = struct;
                newrow.id           = ts_counter;
                newrow.id0          = ts_counter-1;
                newrow.abbreviation = mask_global_list(mask_global_idx, 2);
                newrow.description  = mask_global_list(mask_global_idx, 3);
                newrow.nvoxel       = size(masked_bp_2D,2);
                newrow.type         = {'mask'};
                newrow.source       = {'global'};
                ts_table   = [ts_table;struct2table(newrow)]; %#ok<AGROW>
                    
                
            end % mask_global_idx
            
        end % use_mask_global
        
    end % use_mask
    
    
    %----------------------------------------------------------------------
    % loop over sphere global
    %----------------------------------------------------------------------
    
    if use_sphere
        
        if use_sphere_global
            
            for sphere_global_idx = 1 : size(sphere_global_list,1)
                
                center = sphere_global_list{sphere_global_idx,1};
                radius = sphere_global_list{sphere_global_idx,2};
                abbrev = sphere_global_list{sphere_global_idx,3};
                descrip= sphere_global_list{sphere_global_idx,4};
                
                sphere_global_path = fullfile(outdir_path, [abbrev '.nii']);
                
                %----------------------------------------------------------
                % create sphere global mask
                %----------------------------------------------------------
                if ~exist(sphere_global_path, 'file') || par.redo
                    fprintf('[%s]:          creating sphere global mask : %s \n', mfilename, sphere_global_path)
                    
                    sphere_global_Y = false(size_volume_4D(1:3));
                    sphere_global_Y(sum((XYZmm - center(:)*ones(1,size(XYZmm,2))).^2) <= radius^2) = true;
                    assert(sum(sphere_global_Y(:))>0, 'sphere is empty %d', sphere_global_idx)
                    
                    % write sphere global mask
                    sphere_global_V         = struct;
                    sphere_global_V.fname   = fullfile(outdir_path, [abbrev '.nii']);
                    sphere_global_V.dim     = bp_header(1).dim;
                    sphere_global_V.dt      = [2 bp_header(1).dt(2)];
                    sphere_global_V.mat     = bp_header(1).mat;
                    sphere_global_V.pinfo   = bp_header(1).pinfo;
                    sphere_global_V.descrip = sprintf('sphere : [%g %g %g] %gmm - %s - %s', center(1), center(2), center(3), radius, abbrev, descrip);
                    spm_write_vol(sphere_global_V,sphere_global_Y);
                else
                    sphere_global_V = spm_vol      (sphere_global_path);
                    sphere_global_Y = spm_read_vols(sphere_global_V   );
                end
                sphere_global_Y = logical(sphere_global_Y);
                
                %----------------------------------------------------------
                % extract timeserie
                %----------------------------------------------------------
                masked_bp_2D = bp_2D(:,sphere_global_Y(:));
                masked_bp_2D(~isfinite(masked_bp_2D)) = 0; % infinite values can appear when the label in the mask does not perfectly overlap with input BOLD data
                
                % extract ROI timeseries
                y = extract_first_eigenvariate(masked_bp_2D);
                assert(~any(isnan(y)), 'extracted timeseries contains NaN: %s', sphere_global_path)
                
                % append data
                ts_counter = ts_counter + 1;
                timeseries(:,ts_counter) = y;
                newrow              = struct;
                newrow.id           = ts_counter;
                newrow.id0          = ts_counter-1;
                newrow.abbreviation = {abbrev};
                newrow.description  = {descrip};
                newrow.nvoxel       = size(masked_bp_2D,2);
                newrow.type         = {'sphere'};
                newrow.source       = {'global'};
                ts_table   = [ts_table;struct2table(newrow)]; %#ok<AGROW>
                
            end % sphere_global_idx
            
        end % use_sphere_global
        
    end % use_sphere
    
    % WARNING if duplicates
    [~, uniqueIdx] = unique(ts_table.abbreviation); % Find the indices of the unique strings
    duplicates = ts_table.abbreviation; % Copy the original into a duplicate array
    duplicates(uniqueIdx) = []; % remove the unique strings, anything left is a duplicate
    duplicates = unique(duplicates); % find the unique duplicates
    if ~isempty(duplicates)
        warning('duplicates abbreviation : %s', strjoin(duplicates, ' '))
    end
    
    %------------------------------------------------------------------
    % save timeseries info
    %------------------------------------------------------------------
    save(timeseries_path, 'timeseries', 'ts_table', 'par', 'TR', 'nTR', 'scans');
    fprintf('[%s]:          timeseries saved : %s // %s \n', mfilename, outname, timeseries_path)

    
end % iVol


%% Write jobs for the cluster, if needed

if par.sge
    do_cmd_matlab_sge(job_sge, par);
end


%% Add outputs objects

if obj && par.auto_add_obj && (par.run || par.sge)
    
    for iVol = 1 : length(volumeArray)
        
        % Shortcut
        vol = volumeArray(iVol);
        ser = vol.serie;
        sub = vol.subdir;
        
        if par.run
            
            if ~isempty(sub)
                ser.addVolume(sub, ['^' par.subdir '$'], [      '^' par.clean4D_name '$'],       'clean', 1)
                ser.addVolume(sub, ['^' par.subdir '$'], [   '^bp_' par.clean4D_name '$'],    'bp_clean', 1)
                ser.addVolume(sub, ['^' par.subdir '$'], [ '^ALFF_' par.clean4D_name '$'],  'ALFF_clean', 1)
                ser.addVolume(sub, ['^' par.subdir '$'], ['^fALFF_' par.clean4D_name '$'], 'fALFF_clean', 1)
            else
                ser.addVolume(['^' par.subdir '$'], [      '^' par.clean4D_name '$'],       'clean', 1)
                ser.addVolume(['^' par.subdir '$'], [   '^bp_' par.clean4D_name '$'],    'bp_clean', 1)
                ser.addVolume(['^' par.subdir '$'], [ '^ALFF_' par.clean4D_name '$'],  'ALFF_clean', 1)
                ser.addVolume(['^' par.subdir '$'], ['^fALFF_' par.clean4D_name '$'], 'fALFF_clean', 1)
            end
            
        elseif par.sge
            
            ser.addVolume('root', fullfile(fileparts(vol.path), par.subdir,            par.clean4D_name ),       'clean')
            ser.addVolume('root', fullfile(fileparts(vol.path), par.subdir, [   'bp_'  par.clean4D_name]),    'bp_clean')
            ser.addVolume('root', fullfile(fileparts(vol.path), par.subdir, [ 'ALFF_'  par.clean4D_name]),  'ALFF_clean')
            ser.addVolume('root', fullfile(fileparts(vol.path), par.subdir, ['fALFF_'  par.clean4D_name]), 'fALFF_clean')
            
        end
        
    end % iVol
    
end % obj


end % function

function [TR, nTR, scans] = load_4D_volume_info(volume_path)

volume_header = spm_vol(char(volume_path));
TR = volume_header(1).private.timing.tspace;
nTR = length(volume_header);
scans = cell(nTR,1);
for iTR = 1 : nTR
    scans{iTR} = sprintf('%s,%d', volume_header(iTR).fname, iTR);
end

end

function y = extract_first_eigenvariate(Y)
% "y" size is [nTR nVoxelInMask]

[m,n]   = size(Y);
if m > n
    [~,s,v] = svd(Y'*Y);
    s       = diag(s);
    v       = v(:,1);
    u       = Y*v/sqrt(s(1));
else
    [~,s,u] = svd(Y*Y');
    s       = diag(s);
    u       = u(:,1);
    v       = Y'*u/sqrt(s(1));
end
d       = sign(sum(v));
u       = u*d;
% v       = v*d; % unused
y       = u*sqrt(s(1)/n);

end

function symlink(src, dst, force)
if force
    cmd = sprintf('ln -sf %s %s', src, dst);
else
    cmd = sprintf('ln -s  %s %s', src, dst);
end
unix(cmd);
end

function checksum = hash(input_char)
encoder = java.security.MessageDigest.getInstance('SHA-1');
encoder.update(uint8(input_char));
h = typecast(encoder.digest, 'uint8');
h = lower(dec2hex(h));
checksum = h(:)';
end
