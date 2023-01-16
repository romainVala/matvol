function TS_struct = job_timeseries_to_connectivity_seedbased_pearson_zfisher(TS_struct, par)
%job_timeseries_to_connectivity_seedbased_pearson_zfisher
%
% WORKFLOW
%   1. TS = run job_extract_timeseries_from_atlas(...)
%   2. job_timeseries_to_connectivity_matrix(TS)   <=== this function
%
% SYNTAX
%   TS = job_timeseries_to_connectivity_seedbased_pearson_zfisher(TS)
%   TS = job_timeseries_to_connectivity_seedbased_pearson_zfisher(TS, par)
%
% WROKFLOW
%   load cleaned bandpassed volume (job_extract_timeseries_from_atlas)
%   loead timeseries from the regions (job_extract_timeseries_from_atlas)
%   compute pearson correlation from each reagion to the whole cleaned bandpassed volume
%   compute zfisher from pearson
%   save on disk
%
% See also job_extract_timeseries_from_atlas job_timeseries_to_connectivity_matrix plot_resting_state_connectivity_matrix job_timeseries_to_connectivity_network

if nargin==0, help(mfilename('fullpath')); return; end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

%% defpar

% classic matvol
defpar.redo = 0;

par = complet_struct(par,defpar);


%% main

nVol   = numel(TS_struct              );
nAtlas = numel(TS_struct(1).atlas_name);

for iVol = 1 : nVol
    
    vol_data = TS_struct(iVol); % shortcut
    
    for atlas_idx = 1 : nAtlas
        
        % shortucts
        atlas_name = vol_data.atlas_name{atlas_idx};
        atlas_mdl_dir = fullfile(vol_data.outdir, 'seedbased', atlas_name);
        
        pearson_path = fullfile(atlas_mdl_dir, 'pearson.nii');
        zfisher_path = fullfile(atlas_mdl_dir, 'zfisher.nii');
        TS_struct(iVol).connectivity_seedbased.(atlas_name).pearson = pearson_path;
        TS_struct(iVol).connectivity_seedbased.(atlas_name).zfisher = zfisher_path;
        
        if exist(pearson_path, 'file') && ~par.redo
            fprintf('[%s]: pearson correlation exists :  %d/%d - %s - %s \n', mfilename, iVol, nVol, atlas_name, pearson_path)
            continue
        end
        
        fprintf('[%s]: working on %d/%d %s : %s \n', mfilename, iVol, nVol, atlas_name, vol_data.(atlas_name))
        
        % load timeseries
        fprintf('[%s]:     loading timeseries... ', mfilename)
        timeseries_data = load( vol_data.(atlas_name) );
        nROI = size(timeseries_data.atlas_table,1);
        nTR   = timeseries_data.nTR;
        fprintf('done \n')
        
        % load volume
        fprintf('[%s]:     loading cleaned bandpassed volume... ', mfilename)
        bp_clean_header = spm_vol      (vol_data.bp_clean          );
        bp_clean_4D     = spm_read_vols(bp_clean_header            );                 % [x y z t]
        fprintf('done \n')
        
        % load mask
        fprintf('[%s]:     loading mask... ', mfilename)
        mask_header           = spm_vol      (fullfile(vol_data.outdir, 'mask.nii'));
        mask_3D               = spm_read_vols(mask_header                          ); % [x y z]
        fprintf('done \n')
        
        % convert to 2D array == timeseries [ mask(nVoxel) nTR ]
        mask_1D                 = mask_3D(:);                                         % [     x*y*z  1]
        size_volume_4D          = size(bp_clean_4D);
        size_volume_3D          = size_volume_4D(1:3);
        nVoxel                  = prod(size_volume_3D);
        size_volume_2D          = [nVoxel nTR];
        bp_clean_2D             = reshape(bp_clean_4D, size_volume_2D);               % [     x*y*z  t]
        bp_clean_2D(~mask_1D,:) = [];                                                 % [mask(x*y*z) t];
        nMoxel                  = sum(mask_1D); % number of voxels in mask
        
        % compute pearson coefficients
        fprintf('[%s]:     computing pearson correlation for each ROI (may take a while)... ', mfilename)
        pearson_2D = nan([nMoxel nROI]);
        for iROI = 1 : nROI
            pearson_2D(:,iROI) = mean( bp_clean_2D.*timeseries_data.timeseries(:,iROI)' , 2 ) ./ ( std(bp_clean_2D, [], 2) * std(timeseries_data.timeseries(:,iROI)) );
        end
        pearson_4D = NaN([nVoxel nROI]);
        pearson_4D(mask_1D>0,:) = pearson_2D;
        pearson_4D = reshape(pearson_4D, [size_volume_3D nROI]);
        fprintf('done \n')
        
        % transform pearson to zfisher
        zfisher = atanh(pearson_4D);
        
        % write output volumes
        fprintf('[%s]:     writing output volumes... ', mfilename)
        new = bp_clean_header(1).private;
        new.dat.fname = pearson_path;
        new.dat.dim(4) = nROI;
        new.dat.dtype = 'FLOAT32';
        new.descrip   = ['pearson correlation : ' atlas_name];
        create(new);
        new.dat(:,:,:,:) = pearson_4D;
        new = bp_clean_header(1).private;
        new.dat.fname = zfisher_path;
        new.dat.dim(4) = nROI;
        new.dat.dtype = 'FLOAT32';
        new.descrip   = ['zfisher correlation : ' atlas_name];
        create(new);
        new.dat(:,:,:,:) = zfisher;
        fprintf('done \n')
        
    end
    
end

end % function
