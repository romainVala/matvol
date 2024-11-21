function job = job_amicofit(fdwi,par)
% JOB_AMICOFIT : Fit diffusion data models : NODDI, SANDI, ACTIVEAX
% Only the NODDI model has been implemented (to be coded next).
%
%
%
% Input :
%        fdwi : provide cellstr diffusion image path
%        par  : matvol parameters structure
% Output :
%        generate and save the metric files in a foldername defined in "par.output"
%              in the same directory as the 'fdwi' folder
%
% /!\ To use this function which requires (DIPY env) run :
% source /network/lustre/iss02/cenir/software/irm/conda_env/amico_env
%
%


if ~exist('par'), par = ''; end

defpar.model   = {};     % define the model :{ 'noddi','sandi', 'activeAx'}, (default: noddi)
defpar.bvec    = 'bvec';
defpar.bval    = 'bval';
defpar.mask    = 'nodif_brain_mask';
% defpar.output  = 'amico';    % subfolder name

defpar.do_dtifit = 0;        % Compute standard DTI model 1 or 0

defpar.sge      = 1;
defpar.jobname  = 'AMICO-FIT';
defpar.mem      = '16G';
defpar.nbthread = 1 ;


par = complet_struct(par,defpar);

bvec  = get_file_from_same_dir(fdwi,par.bvec,1);
bval  = get_file_from_same_dir(fdwi,par.bval,1);
mask  = get_file_from_same_dir(fdwi,par.mask,1);

pdir   = get_parent_path(fdwi,1); % parent dir
% output = fullfile(pdir,par.output);
model = '';
    if contains(par.model,'activeAx')
        %        dactivate = r_mkdir(output(nbs),'activateAx');
        %        cmd = sprintf('%scd %s\n',cmd,dactivate{1});
        %        cmd = sprintf('amicofit --activeAx -dwi %s -bval %s -bvec %s -mask %s \n\n',fdwi{nbs},bval{nbs}, bvec{nbs}, mask{nbs});
        disp('activeAx not coded yet')
    end
    
    if contains(par.model,'sandi')
        disp('sandi not coded yet')
        
    end
    
    if any(contains(par.model,'noddi')) || isempty(par.model)
        %dnoddi = r_mkdir(output(nbs),'noddi');
       % cmd = sprintf('%scd %s\n',cmd,dnoddi{1});
        model = [model ' --noddi'];
    end


for nbs=1:length(fdwi)
    
    
    cmd = sprintf('cd %s\n',pdir{nbs});
    cmd = sprintf('%samicofit %s -dwi %s -bval %s -bvec %s -mask %s \n\n',cmd,model,fdwi{nbs},bval{nbs}, bvec{nbs}, mask{nbs});
    job{nbs} = cmd;
    
end

job = do_cmd_sge(job,par);

fprintf('\n\nActivate the AMICO environment using : \nsource /network/lustre/iss02/cenir/software/irm/conda_env/amico_env\n')
pause(2);

end
