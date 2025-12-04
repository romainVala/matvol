function job = job_amicofit(fdwi,par)
% JOB_AMICOFIT : fit diffusion models : NODDI, SANDI, ACTIVEAX
%
% DESCRIPTION:
%     Performs diffusion model fitting using the AMICO Python library.
%     By default, it computes the **NODDI** model. Optionally, it compute 
%     **SANDI** and **ACTIVEAX**.
%     See the 'par' section below for model-specific settings.
%
% Inputs:
%     fdwi: cellstr, paths to the Diffusion-Weighted Imaging (DWI) files.
%     par  : matvol & amicofit parameters
%
% Output :
%        Metric files are saved in the defined folder (par.output) in same directory 
%         as the input 'fdwi' files.
%
% REQUIREMENTS: 
% 
%  conda activate /network/iss/cenir/software/irm/conda_env/envs_old_lustr/amico-env
% 
% For more information see :
%                           https://github.com/daducci/AMICO/wiki
%  
%--------------------------------------------------------------------------

if ~exist('par'), par = ''; end

defpar.model   = 'noddi';             % One choice must be selected :{ 'noddi','sandi', 'activeAx'}, (default: noddi)
defpar.bvec    = 'bvec';
defpar.bval    = 'bval';
defpar.mask    = 'nodif_brain_mask';
defpar.b0_thr  = 50;                  % b0 threshold

% sandi par
defpar.delta       =[];   % Time between pulses (s) 
defpar.smalldelta  =[];   % Pulses duration (s)
defpar.echotime    =[];   % Echo time (s)


% activeAx par
defpar.activate_sheme  = '';           % ActiveAx scheme file for activeAx model 
defpar.do_dtifit = 0;        % Compute standard DTI model 1 or 0

defpar.sge      = 1;
defpar.jobname  = 'AMICO-FIT';
defpar.mem      = '16G';
defpar.sge_nb_coeur  = 8;


par = complet_struct(par,defpar);

bvec  = get_file_from_same_dir(fdwi,par.bvec,1);
bval  = get_file_from_same_dir(fdwi,par.bval,1);
mask  = get_file_from_same_dir(fdwi,par.mask,1);

pdir   = get_parent_path(fdwi,1); % parent dir



tmp_time = '';
switch  par.model
    case 'noddi'
        model = '--noddi'
    case 'sandi'
        model = '--sandi'
        assert(~any(~[length(par.delta) length(par.smalldelta) length(par.echotime)]), 'To fit the SANDI model, define the acquisition parameters.');
        tmp_time = sprintf('-d %s -sd %s -te %s',par.delta, par.smalldelta, par.echotime)
    case 'activeAx'
        model = '--activeAx'
    otherwise
        error('Selected model doesn''t exist')
end

b0_thr = '';
if par.b0_thr ~= 50,  b0_thr =['--b0_thr' par.b0_thr]; end



for nbs=1:length(fdwi) 
    
    cmd = sprintf('cd %s\n',pdir{nbs});
    cmd = sprintf('%samicofit %s -dwi %s -bval %s -bvec %s -mask %s %s %s \n\n',cmd, model,fdwi{nbs},bval{nbs}, bvec{nbs}, mask{nbs}, b0_thr, tmp_time);
    job{nbs} = cmd;
  
end

job = do_cmd_sge(job,par);

fprintf('\n\nActivate the AMICO environment using : \n conda activate /network/iss/cenir/software/irm/conda_env/envs_old_lustr/amico-env\n')
pause(2);

end
