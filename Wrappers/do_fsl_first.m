function fo = do_fsl_first(fin,par)


if ~exist('par'),par ='';end

defpar.fsl_output_format = 'NIFTI_GZ';
defpar.prefix = 'first_all';
defpar.outname = '';
defpar.is_brain_extracted=0;

defpar.sge=0;
defpar.jobname = 'fslfirst';
defpar.walltime = '16:00:00';

par = complet_struct(par,defpar);

if isempty(par.outname)
    fo = addprefixtofilenames(fin,par.prefix);
else
    fo = par.outname;
end

[dirf filename] = get_parent_path(fin);

for k=1:length(fin)
    cmd = sprintf('cd %s\n run_first_all -i %s -o %s ',dirf{k},fin{k},fo{k});
    if par.is_brain_extracted
        cmd=sprintf('%s -b\n',cmd);
    else
        cmd=sprintf('%s \n',cmd);
    end
    
    job{k} = cmd;
end

do_cmd_sge(job,par);

