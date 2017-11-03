function fo = nifti_reg_inversewarp(fwarp,fref,frefw,par)
%fref is the fmov of of fwarp frefw is the ref of the initial fwarp
% reg_transform -def ycpp_nr_n4_s_S02_T1W_to_average_to_mean_rmni.nii.gz defo.nii -ref s_S02_T1W.nii.gz 
% 
% reg_transform -invNrr defo.nii /export/dataCENIR/users/romain.valabregue/QC/template/nireg_tpl1/average_to_mean_rmni.nii invtestdefo.nii.gz 
% 
% reg_transform -invNrr ycpp_nr_n4_s_S02_T1W_to_average_to_mean_rmni.nii.gz /export/dataCENIR/users/romain.valabregue/QC/template/nireg_tpl1/average_to_mean_rmni.nii invtest.nii.gz -ref s_S02_T1W.nii.gz

if ~exist('par','var'),par ='';end

defpar.sge=1;
defpar.jobname = 'nireginvW';
defpar.walltime = '02:00:00';
defpar.prefix = 'i';

par = complet_struct(par,defpar);

if length(frefw)==1
    frefw = repmat(frefw,size(fwarp));
end

[dirw fwarp] = get_parent_path(fwarp);

fo = addprefixtofilenames(fwarp,par.prefix);
fo_def = addprefixtofilenames(fwarp,'defo_');

job={};
for k=1:length(fwarp)
    
    
    cmd = sprintf('cd %s\n',dirw{k});
    cmd = sprintf('%s reg_transform -def %s %s -ref %s \n',cmd,fwarp{k},fo_def{k},fref{k});
    cmd = sprintf('%s reg_transform -invNrr %s %s %s \n',cmd,fo_def{k},frefw{k},fo{k});
 
    job{k} = cmd;
    
end

do_cmd_sge(job,par)

