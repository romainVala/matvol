function fo = do_fsl_abs(f,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end

defpar.fsl_output_format = 'NIFTI_GZ';
defpar.prefix = 'abs';
defpar.sge=0;
defpar.jobname = 'fslabs';
defpar.walltime = '00:10:00';

par = complet_struct(par,defpar);


prefix=par.prefix;


f=cellstr(char(f));

fo = addprefixtofilenames(f,prefix);

for k=1:length(f)
    [pp ff] = fileparts(f{k});
    
    cmd = sprintf('export FSLOUTPUTTYPE=%s;fslmaths %s -abs ',par.fsl_output_format,f{k});
    
    cmd = sprintf('%s %s',cmd,fo{k});
    
    if par.sge
        job{k} = cmd;
    else
        unix(cmd);
    end
    
end

if par.sge
    do_cmd_sge(job,par)
end

