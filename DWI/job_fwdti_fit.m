function job = job_fwdti_fit(fdwi,par)
% JOB_FWDTI_FIT : compute diffusion Tensor metrics  free for free water contamination
% Using the free water elimination model to remove free water contamination
%
% By default this function create the fwDT and metrics (fwFA, fwMD, fwAD and fwRD)
%    turn on do_dtifit to fit standard DTI model and create the default metrics
%
%
%
% Input :
%        fdwi : provide "cellstr" of diffusion image path
%        par  : matvol parameters structure
%
% Output :
%        generate and save the metric files in a foldername defined in "par.output" 
%              in the same directory as the 'fdwi' folder
%
%
% 
% To use this function which requires (DIPY env) run:
%  
% source /network/lustre/iss02/cenir/software/irm/conda_env/dipy_env
% 
%
%*** -------------------------------------------------------------------***


if ~exist('par'), par = ''; end


defpar.bvec    = 'bvec';
defpar.bval    = 'bval';
defpar.mask    = 'nodif_brain_mask';
defpar.output  = 'fwdti';    % subfolder name 

defpar.do_dtifit = 0;        % Compute standard DTI model 1 or 0

defpar.sge      = 1;
defpar.jobname  = 'fwdtifit';
defpar.mem      = '16G';
defpar.nbthread = 1 ;


par = complet_struct(par,defpar);

bvec  = get_file_from_same_dir(fdwi,par.bvec,1);
bval  = get_file_from_same_dir(fdwi,par.bval,1);
mask  = get_file_from_same_dir(fdwi,par.mask,1);

pdir   = get_parent_path(fdwi,1); % parent dir
output = fullfile(pdir,par.output);

dtifit = 'no';
if par.do_dtifit, dtifit = 'yes'; end
    

for nbs=1:length(fdwi)
    cmd      = sprintf('fwdtifit -dwi %s -bval %s -bvec %s -mask %s -o %s -dti %s \n',fdwi{nbs},bval{nbs}, bvec{nbs}, mask{nbs}, output{nbs},dtifit);    
    job{nbs} = cmd;
    
end

job = do_cmd_sge(job,par);

fprintf('\n\nActivate the DIPY environment using : \nsource /network/lustre/iss02/cenir/software/irm/conda_env/dipy_env\n')
pause(3);

end

