function fo = ants_Atropos(fin,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par','var'),par ='';end


defpar.sge=1;
defpar.jobname = 'antsAtropos';
defpar.walltime = '03:00:00';
defpar.prefix = 'Atro_';
defpar.iter = 5;
defpar.partition = [3 4 5];
defpar.smoothing = [0.3 0.01] ; %default 0.3
defpar.mask = 'allmask.nii.gz';
defpar.pvl = 1; % --use-partial-volume-likelihoods

par = complet_struct(par,defpar);


%check mask for all input
for kk=1:length(fin)
    mf = get_file_from_same_dir(fin(kk),par.mask);
    
    if isempty(mf)
        dir=get_parent_path(fin(kk));
        mf = addsuffixtofilenames(dir,['/' par.mask]);
        
        cmd = sprintf('fslmaths %s -mul 0 -add 1 %s',fin{kk},mf{1});
        unix(cmd)
        
    end
end


field=fieldnames(par);
for nf=1:length(field)
    v = getfield(par,field{nf});
    if isnumeric(v)
        if length(v)>1
           fprintf('runing parameter array %s \n',field{nf});
           pp = par;
           for nbpar=1:length(v)
               vv=v(nbpar);
               pp=setfield(pp,field{nf},vv);
               %keyboard
               ants_Atropos(fin,pp)
           end
           return
        end
    end
end



fin = cellstr(char(fin));
fo = addprefixtofilenames(fin,par.prefix);

for k=1:length(fin)
    
    
    suf = sprintf('_K%d_it%d_s%.3f',par.partition,par.iter,par.smoothing);
    suf(findstr(suf,'.'))='';
    
    if par.pvl
        suf = sprintf('%s_pvl',suf);
    end
        
    fo = addprefixtofilenames(fin(k),par.prefix);
    fo = addsuffixtofilenames(fo,suf);
    
    if iscell(par.mask)
        maskf=par.mask{k};
    else
        maskf=par.mask;
    end
    
    [pp ffi]=get_parent_path(fin(k));
    [pp ffo]=get_parent_path(fo);
    cmd{k} =sprintf('cd %s\n Atropos -d3 -c [%d,0] -m [%f,1x1x1] -i kmeans[%d] -a %s -o %s -x %s ',...
        pp{1},par.iter,par.smoothing,par.partition,ffi{1},ffo{1},maskf);
    
    if par.pvl
        cmd{k} = sprintf('%s --use-partial-volume-likelihoods ',cmd{k});
    end
    cmd{k} = sprintf('%s \n',cmd{k});
    
end    

%Atropos -d3 -c [5,0] -m [0.01,1x1x1] -i kmeans[2] -a n4_s_S11_T1_MP2RAGE_0_420iso.nii -o segK2m01.nii -x allmask.nii.gz 


%char(cmd)
job =  do_cmd_sge(cmd,par)