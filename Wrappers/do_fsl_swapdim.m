function fo = do_fsl_swapdim(f,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end

defpar.swap = 'x y z';
defpar.prefix = '';
defpar.sge=0;
defpar.jobname = 'fslswapdim';
defpar.walltime = '00:10:00';

par = complet_struct(par,defpar);

f=cellstr(char(f));

fo = addprefixtofilenames(f,par.prefix);

for k=1:length(f)
    
    cmd = sprintf('fslswapdim %s %s %s',f{k},par.swap,fo{k});
    
    if par.sge
        job{k} = cmd;
    else
       unix(cmd);
    end
    
end

if par.sge
    do_cmd_sge(job,par)
end

