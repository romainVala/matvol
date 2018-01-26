function j=do_fsl_topup(f4D,par,jobappend)

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end

defpar.outsuffix = '_topup';
defpar.sge=1;
defpar.jobname='topup';
defpar.walltime='12:00:00';
par = complet_struct(par,defpar);


for k=1:length(f4D)
    [outdir fin] = fileparts(f4D{k});  fin = change_file_extension(fin,'');  %pour le .nii.gz
    fo = [fin  par.outsuffix];
    
    cmd = sprintf('cd %s;\ntopup --imain=%s --datain=%s --config=%s --out=%s --fout=field_%s --iout=unwarp_%s\n',...
        outdir,fin,'acqp.txt','b02b0.cnf',fo,fo,fo);
    job{k} = cmd;
end

j=do_cmd_sge(job,par,jobappend);
