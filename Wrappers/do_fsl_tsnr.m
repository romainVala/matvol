function out = do_fsl_tsnr(fin,par)


if ~exist('par'),par ='';end
defpar.sge=0;
defpar.software = 'fsl'; %to set the path
defpar.software_version = 5; % 4 or 5 : fsl version
defpar.jobname = 'fslTsnr';
defpar.prefix = 'tSNR';

par = complet_struct(par,defpar);


fin  = cellstr(char(fin));
fout = addprefixtofilenames(fin,par.prefix);

for k=1:length(fin)

    [pp ffin] = get_parent_path(fin(k));

    cmd = sprintf('cd %s',pp{1});
    
    cmd = sprintf('%s\n fslmaths %s -Tmean the_mean_for_tsnr',cmd,ffin{1});
    cmd = sprintf('%s\n fslmaths %s -Tstd  the_std_for_tsnr',cmd,ffin{1});
    cmd = sprintf('%s\n fslmaths the_mean_for_tsnr -div the_std_for_tsnr %s',cmd,fout{k});
    cmd = sprintf('%s\n rm -f the_mean_for_tsnr.nii.gz the_std_for_tsnr.nii.gz\n',cmd);
    
    job{k} = cmd;
end


do_cmd_sge(job,par)
