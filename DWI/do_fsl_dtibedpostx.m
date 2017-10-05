function job = do_fsl_dtibedpostx(f4D_to_fit,par)

if ~exist('par'),par ='';end

defpar.bedpost_dir = 'bedpostdir';
defpar.bvecs = '^bvecs$';
defpar.bvals = '^bvals$';
defpar.mask = 'nodif_brain_mask';
defpar.source=''
defpar.sge=0;
defpar.connectome=0;
defpar.model = 1;
defpar.nb_fibres = 2;


%
defpar.software = 'fsl'; %to set the path
defpar.software_version = 5; % 4 or 5 : fsl version
defpar.jobname = 'dti_bedpostx';
%see also default params from do_cmd_sge

par = complet_struct(par,defpar);

par.bvecs = get_file_from_same_dir(f4D_to_fit,par.bvecs);
par.bvals = get_file_from_same_dir(f4D_to_fit,par.bvals);
par.mask  = get_file_from_same_dir(f4D_to_fit,par.mask);

if par.connectome
    grad_dev = get_file_from_same_dir(f4D_to_fit,'grad_dev');
end

dti_dir = get_parent_path(f4D_to_fit);

for nbs=1:length(f4D_to_fit)
    
    bed_dir = fullfile(dti_dir{nbs},par.bedpost_dir);
    
    if exist(bed_dir)
        unix(['rm -rf ' bed_dir]);
    end
    mkdir(bed_dir);
            
    cmd = sprintf('ln -s %s %s',f4D_to_fit{nbs},fullfile(bed_dir,'data.nii.gz'));
    unix(cmd);
    cmd = sprintf('ln -s %s %s',par.mask{nbs},fullfile(bed_dir,'nodif_brain_mask.nii.gz'));
    unix(cmd);
    cmd = sprintf('ln -s %s %s',par.bvals{nbs},fullfile(bed_dir,'bvals'));
    unix(cmd);
    cmd = sprintf('ln -s %s %s',par.bvecs{nbs},fullfile(bed_dir,'bvecs'));
    unix(cmd);

    if par.connectome
        cmd = sprintf('ln -s %s %s',grad_dev{nbs},fullfile(bed_dir,'grad_dev.nii.gz'));
        unix(cmd);
    end  
    %warning the -g must be first !
    
    cmd = sprintf('%s\nbedpostx %s',par.source,bed_dir);
    
    if par.connectome
       cmd = sprintf('%s -g',cmd);
    end
    
    cmd = sprintf('%s --model=%d --nf=%d --rician ',cmd,par.model,par.nb_fibres);
    
    
    
    %bedpostx hcp -g --nf=3 --rician --model=2
    job{nbs} = cmd;
  
end

do_cmd_sge(job,par)

