function mat_files = job_resting_state_connectivity_matrix(par)
%JOB_RESTING_STATE_CONNECTIVITY_MATRIX
%
% SYNTAX
%   JOB_RESTING_STATE_CONNECTIVITY_MATRIX(par)
%
% "par" is a structure, where each field is described bellow :
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% ALWAYS MANDATORY
%----------------------------------------------------------------------------------------------------------------------------------------------------
%    .
%
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% Optional
%----------------------------------------------------------------------------------------------------------------------------------------------------
%    .
%
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
assert(isfield(par,'volume'), 'par.volume is mandatory, check help')
assert(isfield(par,'confound'), 'par.confound is mandatory, check help')

%----------------------------------------------------------------------------------------------------------------------------------------------------
% Optional
%----------------------------------------------------------------------------------------------------------------------------------------------------
defpar.mask_threshold = 0.8;
defpar.bandpass = [0.01 0.1]; % Hz

%----------------------------------------------------------------------------------------------------------------------------------------------------
% Other
%----------------------------------------------------------------------------------------------------------------------------------------------------

% classic matvol
defpar.run          = 1;
defpar.redo         = 0;
defpar.auto_add_obj = 1;

% cluster
defpar.jobname  = mfilename;
defpar.walltime = '04:00:00';
defpar.mem      = '4G';
defpar.sge      = 0;

par = complet_struct(par,defpar);


%% Some checks

nVol = nan(4,1);

obj = 0;
if isa(par.volume,'volume')
    obj = 1;
    volumeArray = par.volume;
    par.volume = par.volume.getPath();
end
nVol(1) = numel(par.volume);

if isa(par.confound,'rp')
    counfondArray = par.confound;
    par.confound = par.confound.getPath();
end
nVol(2) = numel(par.confound);

use_mask = 0;
if isfield(par, 'mask')
    use_mask = 1;
    if isa(par.mask,'volume')
        maskArray = par.mask;
        par.mask = par.mask.getPath();
    end
    nVol(3) = numel(par.mask);
end

nVol = nVol( ~isnan(nVol) );
assert( all(nVol(1)==nVol), 'different number of subjects on volume/confonnd/mask')
nVol = nVol(1);


%% Main

mat_files = cell(nVol,1);

for iVol = 1:nVol
    
    volume_path = par.volume(iVol);
    outdir_path = fullfile(get_parent_path(char(volume_path)), 'RS_connectivity_matrix');
    
    connectivity_path = fullfile(outdir_path,'connectivity.mat');
    mat_files{iVol} = connectivity_path;
    if exist(connectivity_path, 'file') && ~par.redo
        continue
    end
    
    volume_header = spm_vol(char(volume_path));
    TR = volume_header(1).private.timing.tspace;
    nT = length(volume_header);
    scans = cell(nT,1);
    for iT = 1 : nT
        scans{iT} = sprintf('%s,%d', volume_header(iT).fname, iT);
    end
    
    
    cleaned_volume_path = fullfile(outdir_path, '4D.nii');
    
    %----------------------------------------------------------------------
    % clean input volume from confounds
    %----------------------------------------------------------------------
    
    if ~exist(cleaned_volume_path, 'file') || par.redo
        clear matlabbatch
        
        matlabbatch{1}.spm.stats.fmri_spec.dir = {outdir_path}; %%%
        matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR; %%%
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
        matlabbatch{1}.spm.stats.fmri_spec.sess.scans = scans; %%%
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = par.confound(iVol); %%%%
        matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
        matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
        matlabbatch{1}.spm.stats.fmri_spec.mthresh = par.mask_threshold; %%%
        if use_mask
            matlabbatch{1}.spm.stats.fmri_spec.mask = par.mask(iVol); %%%
        else
            matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
        end
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
        matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
        matlabbatch{2}.spm.stats.fmri_est.write_residuals = 1;
        matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
        matlabbatch{3}.spm.util.cat.vols(1) = cfg_dep('Model estimation: Residual Images', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','res'));
        matlabbatch{3}.spm.util.cat.name = '4D.nii';
        matlabbatch{3}.spm.util.cat.dtype = 0;
        matlabbatch{3}.spm.util.cat.RT = TR; %%%%
    
        spm_jobman('run', matlabbatch)
    end
    
    %----------------------------------------------------------------------
    % get cleaned volume and bandpass it
    %----------------------------------------------------------------------
    
    bp_volume_path = addprefixtofilenames(cleaned_volume_path,'bp_');
    
    if ~exist(bp_volume_path, 'file') || par.redo
    
        % load volume
        cleaned_volume_header = spm_vol(cleaned_volume_path);
        cleaned_volume_4D = spm_read_vols(cleaned_volume_header); % [x y z t]
        
        % load mask
        mask_header = spm_vol(fullfile(outdir_path, 'mask.nii'));
        mask_3D = spm_read_vols(mask_header); % [x y z]
        
        % converto to 2D array == timeseries,
        mask_1D = mask_3D(:); % [x*y*z 1]
        size_volume_4D = size(cleaned_volume_4D);
        size_volume_2D = [prod(size_volume_4D(1:3)) size_volume_4D(4)];
        cleaned_volume_2D = reshape(cleaned_volume_4D, size_volume_2D); % [x*y*z t]
        cleaned_volume_2D(~mask_1D,:) = []; % [mask(x*y*z) t];
        
        % bandpass using FFT
        FFT = fft(cleaned_volume_2D, [], 2) ;
        mag = abs(FFT);
        pha = angle(FFT);
        if mod(nT,2) == 1
            freq = (1/TR) * (0 : (nT/2)) / nT;
            freq = [freq fliplr(freq)];
            freq(end) = [];
        else
            freq = (1/TR) * (0 : (nT/2-1)) / nT;
            freq = [freq fliplr(freq)];
        end
        bp_freq = ones(size(freq));
        bp_freq(freq < par.bandpass(1)) = false;
        bp_freq(freq > par.bandpass(2)) = false;
        bp = real(ifft( mag.*bp_freq .* exp(1i*pha), [], 2)); % [mask(x*y*z) t];
        
        % write bandpass volume
        bp_2D = NaN(size_volume_2D); % [x*y*z t]
        bp_2D(mask_1D>0,:) = bp;
        bp_4D = reshape(bp_2D, size_volume_4D); % [x y z t]
        bp_nifti = cleaned_volume_header(1).private;
        bp_nifti.dat.fname = bp_volume_path;
        create(bp_nifti)
        bp_nifti.dat(:,:,:,:) = bp_4D;
    
    else
        
        bp_header = spm_vol(bp_volume_path);
        bp_4D = spm_read_vols(bp_header); % [x y z t]
        size_volume_4D = size(bp_4D);
        size_volume_2D = [prod(size_volume_4D(1:3)) size_volume_4D(4)];
        mask_header = spm_vol(fullfile(outdir_path, 'mask.nii'));
        mask_3D = spm_read_vols(mask_header); % [x y z]
        mask_1D = mask_3D(:); % [x*y*z 1]
        bp_2D = reshape(bp_4D, size_volume_2D);
    end
    
    %----------------------------------------------------------------------
    % copy atlas and reslice it at functionnal resolution
    %----------------------------------------------------------------------
    
    cat12_atlas_dir = fullfile(spm('dir'), 'toolbox', 'cat12', 'templates_MNI152NLin2009cAsym');
    atlas_name = 'aal3';
    
    if ~exist(fullfile(outdir_path, [atlas_name '.nii']), 'file') || par.redo
        copyfile(fullfile(cat12_atlas_dir, [atlas_name '.nii']), fullfile(outdir_path, [atlas_name '.nii']))
        copyfile(fullfile(cat12_atlas_dir, [atlas_name '.csv']), fullfile(outdir_path, [atlas_name '.csv']))
        copyfile(fullfile(cat12_atlas_dir, [atlas_name '.txt']), fullfile(outdir_path, [atlas_name '.txt']))
    end
    
    resliced_atlas_path = fullfile(outdir_path, ['r' atlas_name '.nii']);
    
    if ~exist(resliced_atlas_path, 'file') || par.redo
        clear matlabbatch
        
        matlabbatch{1}.spm.spatial.coreg.write.ref = volume_path;
        matlabbatch{1}.spm.spatial.coreg.write.source = {fullfile(outdir_path, [atlas_name '.nii'])};
        matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 4;
        matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
        matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
        matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';
        
        spm_jobman('run', matlabbatch)
    end
    
    %----------------------------------------------------------------------
    % load atlas info
    %----------------------------------------------------------------------
    atlas_header = spm_vol(fullfile(outdir_path, ['r' atlas_name '.nii']));
    atlas_3D = spm_read_vols(atlas_header);
    atlas_table = readtable(fullfile(outdir_path, [atlas_name '.csv']));
    values_in_atlas_3D = unique(atlas_3D(:));
    [~,values_in_atlas_table,~] = intersect(atlas_table.ROIid,values_in_atlas_3D);
    atlas_table = atlas_table(values_in_atlas_table,:);
    nROI = size(atlas_table,1);
    
    %----------------------------------------------------------------------
    % extract timeseries
    %----------------------------------------------------------------------
    timeseries = zeros(nT, nROI);
    for iROI = 1 : nROI
        
        % extract voxels in ROI from the bandpassed volume
        mask_ROI_3D = atlas_3D == atlas_table.ROIid(iROI);
        mask_ROI_1D = mask_ROI_3D(:);
        masked_bp_2D = bp_2D(mask_ROI_1D,:);
        masked_bp_2D(~isfinite(masked_bp_2D)) = 0;
        
        % extract first eigenvariate (PCA using SVD)
        y = masked_bp_2D';
        [m,n]   = size(y);
        if m > n
            [v,s,v] = svd(y'*y);
            s       = diag(s);
            v       = v(:,1);
            u       = y*v/sqrt(s(1));
        else
            [u,s,u] = svd(y*y');
            s       = diag(s);
            u       = u(:,1);
            v       = y'*u/sqrt(s(1));
        end
        d       = sign(sum(v));
        u       = u*d;
        v       = v*d;
        Y       = u*sqrt(s(1)/n);

        timeseries(:,iROI) = Y;
    end
    
    connectivity_matrix = corrcoef(timeseries);
    
    save(connectivity_path, 'atlas_table', 'timeseries', 'connectivity_matrix', 'par');
    
    
end % iVol


end % function
