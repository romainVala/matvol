function [ fo, job] = do_mr_noise_remove(f,par,jobappend)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end


defpar.prefix = 'dn_';
defpar.gibbs_prefix = 'dg_';
defpar.noise_prefix = 'noise_level_';
defpar.residual_prefix = 'noise_residual';
defpar.sge=0;
defpar.jobname = 'mr_noise';
defpar.remove_gibs = 0;
defpar.residual=0;
defpar.extractB0 = 0;
defpar.foB0 = '';
defpar.B0_prefix='B0';

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
    %cmd = sprintf('dwidenoise %s - -noise %s |mrdegibbs - %s \n',f{k},fonois{k},fog{k});
    cmd = sprintf('dwidenoise %s %s -noise %s\n',f{k},fo{k},fonois{k});
    ffout = fo{k};
    if par.residual
        cmd = sprintf('%s mrcalc %s %s -subtract %s \n',cmd,f{k},fo{k},fores{k});
    end
    if par.remove_gibs
        cmd = sprintf('%s mrdegibbs %s %s\n',cmd,fo{k},fog{k});
        ffout = fog{k};
    end
    
    if par.extractB0
        if isempty(par.foB0)
            foB0 = addprefixtofilenames(ffout,par.B0_prefix);
        else
            foB0 = par.foB0{k};
        end
        [dd ff] = get_parent_path(ffout);
        cmd = sprintf('%s cd %s\n dwiextract -bzero %s -fslgrad bvecs bvals %s \n',...
            cmd,dd,ff,foB0);
        
    end
    
    job{k} = cmd;
end

job = do_cmd_sge(job,par,jobappend);

if par.remove_gibs
    fo = fog; %finale output name but degibbs prefix
end


