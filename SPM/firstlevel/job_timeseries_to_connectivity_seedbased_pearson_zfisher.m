function TS_struct = job_timeseries_to_connectivity_seedbased_pearson_zfisher(TS_struct, par)
%job_timeseries_to_connectivity_seedbased_pearson_zfisher
%
% WORKFLOW
%   1. TS = run job_extract_timeseries(...)
%   2. job_timeseries_to_connectivity_seedbased_pearson_zfisher(TS)   <=== this function
%
% SYNTAX
%   TS = job_timeseries_to_connectivity_seedbased_pearson_zfisher(TS)
%   TS = job_timeseries_to_connectivity_seedbased_pearson_zfisher(TS, par)
%
% WROKFLOW
%   load cleaned bandpassed volume (job_extract_timeseries)
%   loead timeseries from the regions (job_extract_timeseries)
%   compute pearson correlation from each reagion to the whole cleaned bandpassed volume
%   compute zfisher from pearson
%   save on disk
%
% See also job_extract_timeseries job_timeseries_to_connectivity_matrix plot_resting_state_connectivity_matrix job_timeseries_to_connectivity_network

if nargin==0, help(mfilename('fullpath')); return; end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

% classic matvol
defpar.run          = 1;
defpar.redo         = 0;
defpar.auto_add_obj = 1;

par = complet_struct(par,defpar);


%% main

nVol = numel(TS_struct);

for iVol = 1 : nVol
    
    vol_data = TS_struct(iVol); % shortcut
            
    % shortucts
    outname = vol_data.outname;
    outdir  = vol_data.outdir;
    
    pearson_path = fullfile(outdir, sprintf('seed2voxel_pearson_%s.nii', outname));
    zfisher_path = fullfile(outdir, sprintf('seed2voxel_zfisher_%s.nii', outname));
    TS_struct(iVol).connectivity_seedbased.(outname).pearson = pearson_path;
    TS_struct(iVol).connectivity_seedbased.(outname).zfisher = zfisher_path;
    
    if exist(pearson_path, 'file') && ~par.redo
        fprintf('[%s]: pearson correlation exists :  %d/%d - %s - %s \n', mfilename, iVol, nVol, outname, pearson_path)
        continue
    end
    
    fprintf('[%s]: working on %d/%d %s : %s \n', mfilename, iVol, nVol, outname, vol_data.outname)
    
    % load timeseries
    fprintf('[%s]:     loading timeseries... ', mfilename)
    ts_data = load( vol_data.timeseries_path );
    nROI = size(ts_data.ts_table,1);
    nTR   = ts_data.nTR;
    fprintf('done \n')
    
    % load volume
    fprintf('[%s]:     loading cleaned bandpassed volume... ', mfilename)
    bp_clean_header = spm_vol      (vol_data.bp_clean);
    bp_clean_4D     = spm_read_vols(bp_clean_header   );                          % [x y z t]
    fprintf('done \n')
    
    % load mask
    fprintf('[%s]:     loading mask... ', mfilename)
    mask_header     = spm_vol      (fullfile(vol_data.glmdir, 'mask.nii'));
    mask_3D         = spm_read_vols(mask_header                          );       % [x y z]
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
        pearson_2D(:,iROI) = mean( bp_clean_2D.*ts_data.timeseries(:,iROI)' , 2 ) ./ ( std(bp_clean_2D, [], 2) * std(ts_data.timeseries(:,iROI)) );
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
    new.descrip   = ['pearson correlation : ' outname];
    create(new);
    new.dat(:,:,:,:) = pearson_4D;
    new = bp_clean_header(1).private;
    new.dat.fname = zfisher_path;
    new.dat.dim(4) = nROI;
    new.dat.dtype = 'FLOAT32';
    new.descrip   = ['zfisher correlation : ' outname];
    create(new);
    new.dat(:,:,:,:) = zfisher;
    fprintf('done \n')
    
end % iVol


%% Add outputs objects

for iVol = 1 : nVol
    
    vol_data = TS_struct(iVol); % shortcut
    
    if vol_data.use_obj && par.auto_add_obj && (par.run || par.sge)
        
        % Shortcut
        vol = vol_data.obj.volume;
        ser = vol.serie;
                    
        outdir = fullfile(vol_data.outdir, 'seedbased', outname);
        pearson_path = fullfile(outdir, 'pearson.nii');
        zfisher_path = fullfile(outdir, 'zfisher.nii');
        
        ser.addVolume('root',pearson_path,  [outname '_pearson'])
        ser.addVolume('root',zfisher_path,  [outname '_zfisher'])
                    
    end % obj
    
end % iVol


end % function
