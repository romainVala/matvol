function fo = do_mr_noise_remove(f,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end

defpar.prefix = 'dn_';
defpar.gibbs_prefix = 'dg_';
defpar.noise_prefix = 'noise_level_';
defpar.residual_prefix = 'noise_residual';
defpar.sge=0;
defpar.jobname = 'mr_noise';
defpar.remove_gibs = 0;

defpar.walltime = '00:60:00';

par = complet_struct(par,defpar);



f=cellstr(char(f));

fo = addprefixtofilenames(f,par.prefix);
if par.remove_gibs
    fog = addprefixtofilenames(fo,par.gibbs_prefix);
end

fonois = addprefixtofilenames(f,par.noise_prefix);
fores = addprefixtofilenames(f,par.residual_prefix);
for k=1:length(f)
    
    
    if par.remove_gibs
        cmd = sprintf('dwidenoise %s - -noise %s |mrdegibbs - %s \n',f{k},fonois{k},fog{k});
        
    else
        cmd = sprintf('dwidenoise %s %s -noise %s\n',f{k},fo{k},fonois{k});
        cmd = sprintf('%s mrcalc %s %s -subtract %s',cmd,f{k},fo{k},fores{k});
        
    end
    
    job{k} = cmd;
    
    
end

do_cmd_sge(job,par)

