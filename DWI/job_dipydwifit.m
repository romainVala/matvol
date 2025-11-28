function job = job_dipydwifit(fdwi,par)
% JOB_DIPYDWIFIT : fit diffusion models using DIPY (DTI, Free-Water DTI and DKI)
%                   
%
% DESCRIPTION:
%  
%   Performs diffusion model fitting using the DIPY Python library.
%   By default, it computes the standard Diffusion Tensor Imaging (DTI) model
%   and its metrics (FA, MD, AD, RD).  
%   Free-Water DTI (FWDTI) model can also be fitted to generate
%   free-water–corrected metrics (fwFA, fwMD, fwAD, fwRD, and f).
%   DKI (Diffusion Kurtosis Imaging).
%
%
% Inputs:
%        fdwi: cellstr, paths to the preprocessed diffusion images.
%         par: matvol and dipydwifit parameters.
%
% Output :
%        generate and save the metric files in a foldername defined in "par.output" 
%              in the same directory as the 'fdwi' folder
%
% REQUIREMENTS:
%
%    conda activate /network/iss/cenir/software/irm/conda_env/envs/dipy
%
% *** ------------------------------------------------------------------***


if ~exist('par'), par = ''; end


defpar.bvec    = 'bvec';                        % eddy_rotated_bvecs
defpar.bval    = 'bval';
defpar.mask    = 'dill_nodif_brain_mask';
defpar.output  = 'dipydwi';                 % subfolder name 

defpar.do_dti   = 1;                        % Compute standard DTI model 1 or 0
defpar.do_fwdti = 0;                        % Compute  FWDTI model 1 or 0
defpar.do_dki   = 0;                        % Compute  DKI model 1 or 0
% defpar.do_xxx                             % Future models 
 
defpar.sge      = 1;
defpar.jobname  = 'fwdtifit';
defpar.mem      = '16G';
defpar.nbthread = 4;


par = complet_struct(par,defpar);

bvec  = get_file_from_same_dir(fdwi,par.bvec,1);
bval  = get_file_from_same_dir(fdwi,par.bval,1);
mask  = get_file_from_same_dir(fdwi,par.mask,1);

pdir   = get_parent_path(fdwi,1); % parent dir
output = fullfile(pdir,par.output);

dtifit = '-dti no';
if par.do_dti, dtifit = '-dti yes'; end
fwdti = '';
if par.do_fwdti, fwdti = '-fwdti yes'; end

DKI = '';
if par.do_dki, DKI = '-dki yes'; end


for nbs=1:length(fdwi)
    cmd      = sprintf('dipydwifit -dwi %s -bval %s -bvec %s -m %s -o %s %s %s %s\n',fdwi{nbs},bval{nbs}, bvec{nbs}, mask{nbs}, output{nbs},dtifit, fwdti,DKI);    
    job{nbs} = cmd;
    
end

job = do_cmd_sge(job,par);

fprintf('\n\nActivate the DIPY environment using : \nconda activate /network/iss/cenir/software/irm/conda_env/envs/dipy\n\n')
pause(1);

end
