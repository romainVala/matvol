function job =  mrtrix_buildTemplate(fimg,par)
% MRTRIX_BUILDTEMPLATE : Creates a template from a series of images
%                         using the MRtrix3 command: population_template 
%
% DESCRIPTION:
%     Generates anunbiased group-average template from a series of images, 
%     using 'population_template', which requires an input directory containing
%     all images.
%
%     This function creates the necessary  input folders, such as 
%     [par.outdir]/template/fod_input and [par.outdir]/template/mask_input, 
%     and then links the input images into these folders.
%
%    (Registeration ?)
%      
% Inputs:
%
%     fimg : cellstr, paths to the series of image files (e.g., FODs, masks ...).            
%     par  :  matvol and population_template parameters.
%
% Output:
%
%     The output template image, named as defined in [par.outdir], or the 
%     job files required for running the process on a cluster. 
%
% REQUIREMENTS:
%     module load FreeSurfer/xxx
%    Replace 'xxx' with the desired version number.
%---------------------------------------------------------------------------
if ~exist('par','var'), par = ''; end

defpar.voxel_size        = 1.25;                   % (number) define the voxel size for the Template image (default value = 1.25 mm)
defpar.outname           = 'wmfod_template.nii';   % (char) define the name of the Template
defpar.mask_name         = '';                     % (char) filename of the input mask, must be in the same fdwi folder.
defpar.outdir            = '';                     % (char) define the path where to creat "template" folder
defpar.registration_type = '';                     % default


% defpar.wrapfield         = 1;       % Compute registration to create wraped filed.
defpar.do_maskTemplate   = 1;         % Use 1 or 0


defpar.redo          = 0;             % Use 0 or 1.
defpar.sge           = 1;
defpar.jobname       = 'fodTemplate';
defpar.nthreads      = 12 ;
defpar.walltime      ='96:00:00';     %  depends on the numbre ans size of images (36H default)
defpar.mem           ='16G';
defpar.workflow      = 0;       % Use 0 or 1.


par = complet_struct(par,defpar);


assert(~isempty(par.mask_name),'par.mask_name must be defined');
assert(~isempty(par.outdir),'par.outdir must be defined');

fmask = fullfile(get_parent_path(fimg,1),par.mask_name);

% Prepare data
cmd = sprintf('mkdir -p %s/template/fod_input',par.outdir);
cmd = sprintf('%s\nmkdir %s/template/mask_input',cmd,par.outdir);

for nbr = 1:length(fimg)
    
    cmd = sprintf('%s\nln -sr %s  %s/template/fod_input/input_image_%02d.nii',cmd, fimg{nbr}, par.outdir,nbr);
    cmd = sprintf('%s\nln -sr %s  %s/template/mask_input/input_image_%02d.nii',cmd, fmask{nbr}, par.outdir,nbr);
end

job = {};
if par.sge
    job{end+1} = cmd;
else
    unix(cmd);
end

cmd = ['cd ' par.outdir];
if par.do_maskTemplate
    cmd = sprintf('%s\npopulation_template -nthreads %d template/fod_input -mask_dir template/mask_input template/%s -voxel_size %f -template_mask template/mask_template.nii -force',cmd, par.nthreads,par.outname,par.voxel_size)
    
else
    cmd = sprintf('%s\npopulation_template -nthreads %d template/fod_input -mask_dir template/mask_input template/%s -voxel_size %f -force',cmd, par.nthreads,par.outname,par.voxel_size)
end

job{end+1} = cmd;

[~, do_qsub_file] = do_cmd_sge(job,par);
split_dependency_job(do_qsub_file, 1);

border = repmat('-', 1, 100);
fprintf('%s\n\n      Don''t forget :\n  module load FreeSurfer/xxx\nReplace ''xxx'' with the desired version number.\n%s\n', border, border);


end
