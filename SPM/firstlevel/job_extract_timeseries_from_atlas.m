function TS_struct = job_extract_timeseries_from_atlas(par)
%job_extract_timeseries_from_atlas
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
%   TS = job_extract_timeseries_from_atlas(par)
%
% AFTER
%   whole timeseries connectivity matrix : job_timeseries_to_connectivity_matrix + plot_resting_state_connectivity_matrix
%   whole timeseries seedbased connectivity : job_timeseries_to_connectivity_seedbased
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
%    .atlas_name = (char/cellstr)  available atlas in CAT12 are : 
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
defpar.atlas_name     = {'aal3', 'lpba40'};
defpar.write_ALFF     = true;
defpar.write_fALFF    = true;

defpar.subdir         = 'rsfc';
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


%% Lmitations

assert(~par.sge, 'par.sge=1 not working with this purely matlab code')


%% Some checks

par.atlas_name = cellstr(par.atlas_name);
nAtlas = length(par.atlas_name);
cat12_atlas_dir = fullfile(spm('dir'), 'toolbox', 'cat12', 'templates_MNI152NLin2009cAsym');

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

use_mask = 0;
if isfield(par, 'mask')
    use_mask = 1;
    if isa(par.mask,'volume')
        par.mask = par.mask.getPath();
    end
    nVol(3) = numel(par.mask);
end

nVol = nVol( ~isnan(nVol) );
assert( all(nVol(1)==nVol), 'different number of subjects on volume/confonnd/mask')
nVol = nVol(1);


%% main

TS_struct = struct;

for iVol = 1:nVol
    
    % prepare output dir path
    volume_path = par.volume(iVol);
    fprintf('[%s]: volume %d/%d : %s \n', mfilename, iVol, nVol, char(volume_path))
    outdir_path         = fullfile(get_parent_path(char(volume_path)), par.subdir);
    cleaned_volume_path = fullfile(outdir_path, par.clean4D_name);
    bp_volume_path      = addprefixtofilenames(cleaned_volume_path,'bp_');
    
    % output_struct
    TS_struct(iVol).volume     = char(par.volume  (iVol));
    TS_struct(iVol).confound   = char(par.confound(iVol));
    TS_struct(iVol).outdir     = outdir_path;
    TS_struct(iVol).clean      = cleaned_volume_path;
    TS_struct(iVol).bp_clean   = bp_volume_path;
    TS_struct(iVol).bandpass   = par.bandpass;
    TS_struct(iVol).atlas_name = par.atlas_name;
    TS_struct(iVol).use_obj    = obj;
    if TS_struct(iVol).use_obj
        TS_struct(iVol).obj.volume = volumeArray(iVol);
    end
    
    atlas_idx_list = true(nAtlas, 1);
    for atlas_idx = 1 : nAtlas
        
        % prepare output atlas connectivity
        atlas_name = par.atlas_name{atlas_idx};
        atlas_timeseries_path = fullfile(outdir_path,sprintf('timeseries_%s.mat', atlas_name));
        TS_struct(iVol).(atlas_name) = atlas_timeseries_path;
        
        if exist(atlas_timeseries_path, 'file') && ~par.redo
            fprintf('[%s]:          atlas done : %s \n', mfilename, atlas_name)
            atlas_idx_list(atlas_idx) = false;
        else
            fprintf('[%s]:          atlas todo : %s \n', mfilename, atlas_name)
        end
    end
    
    % if all atlas are done, just skip everything
    if all(~atlas_idx_list) && ~par.redo
        continue
    end
        
    if ~exist(cleaned_volume_path, 'file') || par.redo
        
        if par.redo
            do_delete(outdir_path,0)
        end
        
        % fetch TR and number of timepoints (nTR)
        fprintf('[%s]:      fetch TR and number of timepoints \n', mfilename)
        [TR, nTR, scans] = load_4D_volume_info(volume_path);
        
        %----------------------------------------------------------------------
        % clean input volume from confounds
        %----------------------------------------------------------------------
        fprintf('[%s]:      cleaning volume from confounds \n', mfilename)
        
        clear matlabbatch
        
        matlabbatch{1}.spm.stats.fmri_spec.dir = {outdir_path}; %%%
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
        if use_mask
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
        cleaned_volume_4D     = spm_read_vols(cleaned_volume_header            ); % [x y z t]
        
        % load mask
        mask_header           = spm_vol      (fullfile(outdir_path, 'mask.nii'));
        mask_3D               = spm_read_vols(mask_header                      ); % [x y z]
        
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
        bp = real(ifft( mag.*bp_freq .* exp(1i*pha), [], 2)); % [mask(x*y*z) t];
        
        % ALFF
        if par.write_ALFF
            fprintf('[%s]:      writing  ALFF \n', mfilename)
            
            ALFF = mean(sqrt(mag(:,bp_freq)),2);                          % [mask(x*y*z) 1];
            
            % unmask : [mask(x*y*z) 1 ] ---> [x y z]
            ALFF_2D              = NaN(nVoxel,1);                         % [x*y*z 1]
            ALFF_2D(mask_1D>0,:) = ALFF;
            ALFF_3D              = reshape(ALFF_2D, size_volume_4D(1:3)); % [x y z]
            
            % write volume
            V_ALFF = struct;
            V_ALFF.fname   = addprefixtofilenames(cleaned_volume_path,'ALFF_');
            V_ALFF.dim     = cleaned_volume_header(1).dim;
            V_ALFF.dt      = cleaned_volume_header(1).dt;
            V_ALFF.mat     = cleaned_volume_header(1).mat;
            V_ALFF.pinfo   = cleaned_volume_header(1).pinfo;
            V_ALFF.descrip = sprintf('ALFF [%g %g]', par.bandpass(1), par.bandpass(2));
            spm_write_vol(V_ALFF,ALFF_3D);
        end
        
        % fALFF
        if par.write_fALFF
            fprintf('[%s]:      writing fALFF \n', mfilename)
            
            fALFF = sum(mag(:,bp_freq),2) ./ sum(mag(:,~bp_freq),2);        % [mask(x*y*z) 1];
            
            % unmask : [mask(x*y*z) 1 ] ---> [x y z]
            fALFF_2D              = NaN(nVoxel,1);                          % [x*y*z 1]
            fALFF_2D(mask_1D>0,:) = fALFF;
            fALFF_3D              = reshape(fALFF_2D, size_volume_4D(1:3)); % [x y z]
            
            % write volume
            V_fALFF = struct;
            V_fALFF.fname   = addprefixtofilenames(cleaned_volume_path,'fALFF_');
            V_fALFF.dim     = cleaned_volume_header(1).dim;
            V_fALFF.dt      = cleaned_volume_header(1).dt;
            V_fALFF.mat     = cleaned_volume_header(1).mat;
            V_fALFF.pinfo   = cleaned_volume_header(1).pinfo;
            V_fALFF.descrip = sprintf('fALFF [%g %g]', par.bandpass(1), par.bandpass(2));
            spm_write_vol(V_fALFF,fALFF_3D);
        end
        
        % write bandpass volume
        fprintf('[%s]:      writing bandpassed volume \n', mfilename)
        bp_2D = NaN(size_volume_2D); % [x*y*z t]
        bp_2D(mask_1D>0,:) = bp;
        bp_4D = reshape(bp_2D, size_volume_4D); % [x y z t]
        bp_nifti = cleaned_volume_header(1).private;
        bp_nifti.dat.fname = bp_volume_path;
        bp_nifti.descrip = sprintf('bandpass [%g %g]', par.bandpass(1), par.bandpass(2));
        create(bp_nifti)
        bp_nifti.dat(:,:,:,:) = bp_4D;
    
    else
        
        fprintf('[%s]:      loading filtered (bandpass) volume \n', mfilename)
        
        bp_header = spm_vol      (bp_volume_path);
        bp_4D     = spm_read_vols(bp_header     ); % [x y z t]
        
        size_volume_4D = size(bp_4D);
        nVoxel         = prod(size_volume_4D(1:3));
        size_volume_2D = [nVoxel nTR];
        
        bp_2D = reshape(bp_4D, size_volume_2D);    % [ x*y*z  t]
        
    end
    
    
    %----------------------------------------------------------------------
    % loop over atlases
    %----------------------------------------------------------------------
    
    for atlas_idx = 1 : nAtlas
        
        if atlas_idx_list(atlas_idx)
            atlas_name              = par.atlas_name{atlas_idx};
            atlas_timeseries_path = fullfile(outdir_path,sprintf('timeseries_%s.mat', atlas_name));
        else
            continue
        end
        
        
        %------------------------------------------------------------------
        % copy atlas and reslice it at functionnal resolution
        %------------------------------------------------------------------
        
        % copy
        if ~exist(fullfile(outdir_path, [atlas_name '.nii']), 'file') || par.redo
            fprintf('[%s]:          copy atlas files : %s \n', mfilename, atlas_name)
            copyfile(fullfile(cat12_atlas_dir, [atlas_name '.nii']), fullfile(outdir_path, [atlas_name '.nii']))
            copyfile(fullfile(cat12_atlas_dir, [atlas_name '.csv']), fullfile(outdir_path, [atlas_name '.csv']))
            copyfile(fullfile(cat12_atlas_dir, [atlas_name '.txt']), fullfile(outdir_path, [atlas_name '.txt']))
        end
        
        % atlas
        resliced_atlas_path = fullfile(outdir_path, ['r' atlas_name '.nii']);
        if ~exist(resliced_atlas_path, 'file') || par.redo
            fprintf('[%s]:          reslice atlas to functional resolution : %s \n', mfilename, atlas_name)
            
            clear matlabbatch
            matlabbatch{1}.spm.spatial.coreg.write.ref             = volume_path;
            matlabbatch{1}.spm.spatial.coreg.write.source          = {fullfile(outdir_path, [atlas_name '.nii'])};
            matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 4;
            matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap   = [0 0 0];
            matlabbatch{1}.spm.spatial.coreg.write.roptions.mask   = 0;
            matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';
            spm_jobman('run', matlabbatch)
        end
        
        
        %----------------------------------------------------------------------
        % load atlas .nii and .csv
        %----------------------------------------------------------------------
        atlas_header = spm_vol      (fullfile(outdir_path, ['r' atlas_name '.nii']));
        atlas_3D     = spm_read_vols(atlas_header                                  );
        atlas_table  = readtable    (fullfile(outdir_path, [    atlas_name '.csv']));
        
        % we need to make sure that all lines in the csv file correspond to a value in the nifti
        % for exemple, aal3 misses a few values in the .nii compared to its .csv
        values_in_atlas_3D = unique(atlas_3D(:));
        [~,values_in_atlas_table,~] = intersect(atlas_table.ROIid,values_in_atlas_3D);
        atlas_table = atlas_table(values_in_atlas_table,:);
        
        nROI = size(atlas_table,1);
        atlas_table.idx_from_0 = (0:(nROI-1))';              % for visu in 4D, when index start from 0
        atlas_table.idx_from_1 = atlas_table.idx_from_0 + 1; % for visu in 4D, when index start from 1
        % atlas_table = movevars(atlas_table,'idx_from_0', 'after', 'ROIid'); % function introduced in R2018a
        
        %------------------------------------------------------------------
        % extract timeseries in ROIs
        %------------------------------------------------------------------
        timeseries = zeros(nTR, nROI);
        for iROI = 1 : nROI
            
            % extract voxels in ROI from the bandpassed volume
            mask_ROI_3D = atlas_3D == atlas_table.ROIid(iROI);
            mask_ROI_1D = mask_ROI_3D(:);
            masked_bp_2D = bp_2D(mask_ROI_1D,:);
            masked_bp_2D(~isfinite(masked_bp_2D)) = 0; % infinite values can appear when the label in the mask does not perfectly overlap with input BOLD data
            
            % extract first eigenvariate (PCA using SVD)
            y = masked_bp_2D';
            [m,n]   = size(y);
            if m > n
                [~,s,v] = svd(y'*y);
                s       = diag(s);
                v       = v(:,1);
                u       = y*v/sqrt(s(1));
            else
                [~,s,u] = svd(y*y');
                s       = diag(s);
                u       = u(:,1);
                v       = y'*u/sqrt(s(1));
            end
            d       = sign(sum(v));
            u       = u*d;
            % v       = v*d; % unused
            Y       = u*sqrt(s(1)/n);
            
            timeseries(:,iROI) = Y;
        end
        
        %------------------------------------------------------------------
        % save timeseries info
        %------------------------------------------------------------------
        save(atlas_timeseries_path, 'atlas_table', 'timeseries', 'par', 'TR', 'nTR', 'scans');
        fprintf('[%s]:          atlas timeseries saved : %s // %s \n', mfilename, atlas_name, atlas_timeseries_path)
        
    end
    
end % iVol


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
