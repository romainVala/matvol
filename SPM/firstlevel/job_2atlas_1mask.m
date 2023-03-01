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
%                                     % id_atlas1  operator  id_atlas2   outname
%                                           7        'AND'        3       'lSFG'
%                                           7        'AND'        4       'rSFG'
%                                           7        'OR'         5       'lMFG'
%                                           7        'OR'         6       'rMFG'
%                                           7        'XOR'        7       'lIFGoperc'
%                                           7        'NAND'       8       'rIFGoperc'
%                                           7        'NOR'        9       'lIFGtriang'
%                                           7        'XNOR'      10       'rIFGtriang'
%                                 };
%                      'operator' can be logic gates : https://en.wikipedia.org/wiki/Logic_gate
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
atlas1_name          = spm_file(par.atlas1, 'filename');
atlas2_name          = spm_file(par.atlas2, 'filename');
atlas1_path          = fullfile(par.outdir,      atlas1_name );
atlas2_path          = fullfile(par.outdir,      atlas2_name );
resliced_atlas2_path = fullfile(par.outdir, ['r' atlas2_name]);

% labels
assert(iscell(par.labels), 'par.labels must be cell')
assert(size(par.labels,2) >=4, 'par.labels must be at lease 4 columns (extra columns for your own usage)' )
label_id_atlas1 = par.labels(:,1);
label_operator  = par.labels(:,2);
label_id_atlas2 = par.labels(:,3);
label_outname   = par.labels(:,4);
try
    label_id_atlas1 = cell2mat(label_id_atlas1);
catch 
    error('par.label(:,1) must be only numbers')
end
assert(iscellstr(label_operator), 'par.label(:,3) must be cellstr')
try
    label_id_atlas2 = cell2mat(label_id_atlas2);
catch 
    error('par.label(:,3) must be only numbers')
end
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
    mask_atlas1 = Y_atlas1 == label_id_atlas1(l);
    mask_atlas2 = Y_atlas2 == label_id_atlas2(l);
    switch label_operator{l}
        case 'AND'
            Y_mask =  and(mask_atlas1,mask_atlas2);
        case 'OR'
            Y_mask =   or(mask_atlas1,mask_atlas2);
        case 'XOR'
            Y_mask =  xor(mask_atlas1,mask_atlas2);
        case 'NAND'
            Y_mask = ~and(mask_atlas1,mask_atlas2);
        case 'NOR'
            Y_mask =  ~or(mask_atlas1,mask_atlas2);
        case 'XNOR'
            Y_mask = ~xor(mask_atlas1,mask_atlas2);
        otherwise
            error('bad operator, check help')
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
    V_mask.descrip = sprintf('%d  %s  %d --- %s', label_id_atlas1(l), label_operator{l}, label_id_atlas2(l), label_outname{l});
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
