function concat_dti_fsl(f4Ds,outdirs,par)

if ~exist('par','var'),par ='';end

defpar.bvecs = 'bvecs';
defpar.bvals = 'bvals';

par = complet_struct(par,defpar);

for nbs = 1:length(outdirs)
    f4D = cellstr(f4Ds{nbs});
    outdir = outdirs(nbs);
    
    dir4D=get_parent_path(f4D);
    %in case you 3D volume you'll end on dir per volume so reduce to unique dirs
    [bb aa]=unique(char(dir4D),'rows','stable'); %stable pour preserver l'ordre
    dir4D = cellstr(bb);
    
    bvec_f = get_subdir_regex_files(dir4D,par.bvecs);
    bval_f = get_subdir_regex_files(dir4D,par.bvals);
    
    fo=addsuffixtofilenames(outdir,'/4D_dti');
    
    do_fsl_merge(f4D,fo{1},par);    
    
    bval=[];bvec=[];
    for k=1:length(bval_f)
        aa = load(deblank(bval_f{k}));
        bb = load(deblank(bvec_f{k}));
        bval = [bval aa];
        bvec = [bvec,bb];
    end
    
    
    %make B0 real B0
    bval(bval<50) = 0;
    
    %Writing bvals and bvec
    outdir=char(outdir);
    
    fid = fopen(fullfile(outdir,'bvals'),'w');
    fprintf(fid,'%d ',bval);  fprintf(fid,'\n');  fclose(fid);
    
    fid = fopen(fullfile(outdir,'bvecs'),'w');
    for kk=1:3
        fprintf(fid,'%f ',bvec(kk,:));
        fprintf(fid,'\n');
    end
    fclose(fid);
    
end
