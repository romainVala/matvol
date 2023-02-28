function job_2atlas_1mask( par )
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% MANDATORY
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
%    .outdir  (char)  /path/to/my_labels_dir
%    .atlas1  (char)  /path/to/atlas1.nii
%    .atlas2  (char)  /path/to/atlas2.nii
%
%    .labels  (cell)  such as :
%                                 par.labels = {
%                                     % id_atlas1 id_atlas2 operator  outname
%                                               7         3      '*'  'lSFG'
%                                               7         4      '*'  'rSFG'
%                                               7         5      '*'  'lMFG'
%                                               7         6      '*'  'rMFG'
%                                               8         7      '+'  'lIFGoperc'
%                                               8         8      '+'  'rIFGoperc'
%                                               8         9      '*'  'lIFGtriang'
%                                               8        10      '*'  'rIFGtriang'
%                                               9        11      '-'  'lIFGorb'
%                                               9        12      '-'  'rIFGorb'
%                                 };
%
%
%----------------------------------------------------------------------------------------------------------------------------------------------------
% Optional
%----------------------------------------------------------------------------------------------------------------------------------------------------
%
%    .subdir  (char)  name of the subdir where individual mask will be saved
%                     .outdir will contain the original atlas, resliced atlas, and extracted labels == new "atlas" for visualization
%
%
% See also

if nargin==0, help(mfilename('fullpath')); return; end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

%% defpar

%----------------------------------------------------------------------------------------------------------------------------------------------------
% ALWAYS MANDATORY
%----------------------------------------------------------------------------------------------------------------------------------------------------
assert(isfield(par,'outdir'), 'par.outdir is mandatory, check help')
assert(isfield(par,'atlas1'), 'par.atlas1 is mandatory, check help')
assert(isfield(par,'atlas2'), 'par.atlas2 is mandatory, check help')
assert(isfield(par,'labels'), 'par.labels is mandatory, check help')

%----------------------------------------------------------------------------------------------------------------------------------------------------
% Optional
%----------------------------------------------------------------------------------------------------------------------------------------------------
defpar.subdir = 'mask';

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


%% Preparations

% complet subdir path
subdir_path = fullfile(par.outdir, par.subdir);

% outidr
if ~exist(subdir_path, 'dir')
    mkdir(subdir_path)
end

% atlas
atlas1_path          = fullfile(par.outdir,      spm_file(par.atlas1, 'filename') );
atlas2_path          = fullfile(par.outdir,      spm_file(par.atlas2, 'filename') );
resliced_atlas2_path = fullfile(par.outdir, ['r' spm_file(par.atlas2, 'filename')]);

% labels
label_outname = par.labels(:,4);
unique_label_outname = unique(label_outname);
assert(length(label_outname) == length(unique_label_outname), 'non-unique label outname !')
nLabel = length(label_outname);


%% Copy & reslice if necessary

% copy
if ~exist(atlas1_path,'file')
    copyfile(par.atlas1, atlas1_path);
end
if ~exist(atlas2_path,'file')
    copyfile(par.atlas2, atlas2_path);
end

% reslice ?
if ~exist(resliced_atlas2_path,'file')
    V_atlas1 = spm_vol(atlas1_path);
    V_atlas2 = spm_vol(atlas2_path);
    if spm_check_orientations([V_atlas1, V_atlas2], false)
        symlink(atlas2_path, resliced_atlas2_path, par.redo);
    else
        fprintf('[%s]: reslice atlas2 to atlas1 \n', mfilename)

        clear matlabbatch
        matlabbatch{1}.spm.spatial.coreg.write.ref             = {atlas1_path};
        matlabbatch{1}.spm.spatial.coreg.write.source          = {atlas2_path};
        matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 0; % nearest interpolation, to avoid voxel blending
        matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap   = [0 0 0];
        matlabbatch{1}.spm.spatial.coreg.write.roptions.mask   = 0;
        matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';
        spm_jobman('run', matlabbatch)
    end
end


%% Load atlas

V_atlas1 = spm_vol(         atlas1_path);
V_atlas2 = spm_vol(resliced_atlas2_path);

Y_atlas1 = spm_read_vols(V_atlas1);
Y_atlas2 = spm_read_vols(V_atlas2);


%% Generat masks

% already done ?
basename = spm_file(par.outdir, 'basename');
my_labels_path = fullfile(par.outdir, [basename '.nii']);
if exist(my_labels_path, 'file') && ~par.redo
    fprintf('[%s]: labels already exist %s : %s \n', mfilename, basename, my_labels_path)
    return
end

mask_4D = zeros([size(Y_atlas1) nLabel]);

for l = 1 : nLabel
    
    % compute mask
    mask_atlas1 = Y_atlas1 == par.labels{l, 1};
    mask_atlas2 = Y_atlas2 == par.labels{l, 2};
    switch par.labels{l, 3}
        case '*'
            Y_mask = mask_atlas1 .* mask_atlas2;
        case '+'
            Y_mask = mask_atlas1  + mask_atlas2;
        case '-'
            Y_mask = mask_atlas1  - mask_atlas2;
        otherwise
            error('bad operator')
    end
    
    mask_4D(:,:,:,l) = l * Y_mask;
    
    % write mask
    mask_outname = fullfile(subdir_path, [label_outname{l} '.nii']);
    if exist(mask_outname, 'file')
        continue
    end
    fprintf('[%s]: writing mask %s : %s \n', mfilename, label_outname{l}, mask_outname)
    V_mask         = struct;
    V_mask.fname   = mask_outname;
    V_mask.dim     = V_atlas1.dim;
    V_mask.dt      = [2 V_atlas1.dt(2)];
    V_mask.pinfo   = V_atlas1.pinfo;
    V_mask.mat     = V_atlas1.mat;
    V_mask.descrip = sprintf('%d --- %d --- %s --- %s', par.labels{l, 1}, par.labels{l, 2}, par.labels{l, 3}, par.labels{l, 4});
    spm_write_vol(V_mask, Y_mask);
    
end

fprintf('[%s]: writing labels %s : %s \n', mfilename, basename, my_labels_path)
V_label         = struct;
V_label.fname   = my_labels_path;
V_label.dim     = V_atlas1.dim;
if nLabel > 255
    type = spm_type('uint16'); % 65535 labels
else
    type = spm_type('uint8' ); %   255 labels
end
V_label.dt      = [type V_atlas1.dt(2)];
V_label.pinfo   = V_atlas1.pinfo;
V_label.mat     = V_atlas1.mat;
V_label.descrip = sprintf('%s --- labels go from %d to %d',basename, 1, nLabel);
spm_write_vol(V_label, sum(mask_4D,4));


end

function symlink(src, dst, force)
if force
    cmd = sprintf('ln -sf %s %s', src, dst);
else
    cmd = sprintf('ln -s  %s %s', src, dst);
end
unix(cmd);
end
