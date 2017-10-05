function transform_4D_to_oneB04D(fi_4D,par)

if ~exist('par')
    par='';
end
if ~exist('fi_4D'), fi_4D='';end

if ~isfield(par,'subdir'),  par.subdir = 'oneB0_4Ddir' ; end
if ~isfield(par,'vol_sufix'),  par.vol_sufix = '_trackvis' ; end
if ~isfield(par,'bval'),  par.bval = 'bvals'; end
if ~isfield(par,'bvec'),  par.bvec = 'bvecs'; end
if ~isfield(par,'do4D');  par.do4D = 1; end
if ~isfield(par,'doB0mean');  par.doB0mean = 1; end
if ~isfield(par,'dosusan');  par.dosusan = 1; end
if ~isfield(par,'susan_noise');  par.susan_noise = 100; end

if isempty(fi_4D)
    fi_4D = spm_select(inf,'.*','select 4D data','',pwd);fi_4D= cellstr(fi_4D);
end

for k=1:length(fi_4D)
    
    [p,ff,e] = fileparts(fi_4D{k});
    
    if findstr(ff,'.')
        [ppp ff e] = fileparts(ff);
    end
    
    if strcmp(par.subdir(1),'/')
        outdir = par.subdir;
    else
        outdir = deblank(fullfile(p,par.subdir));
    end
    
    if ~exist(outdir), mkdir(outdir);  end
    
    bval = load(fullfile(p,par.bval));
    bvec = load(fullfile(p,par.bvec));
    
    if size(bval,2)==1, bval=bval';end
    if size(bvec,2)==3, bvec=bvec';end
    
    ind = find(bval==0);
    if isempty(ind)
        ind = find(bval<50);
        bval(ind)=0;
    end
    
    for kind=1:length(ind)
        B0name = ['theB0_' num2str(kind)];
        Bdirname = ['theBdir_' num2str(kind)];
        
        do_fsl_roi(fi_4D(k),B0name,ind(kind)-1,1);
        if par.do4D==1
            
            if kind == length(ind)
                if ind(kind)<length(bval) %you have no b0 at the end
                    do_fsl_roi(fi_4D(k),Bdirname,ind(kind),length(bval)-ind(kind));
                end
                
            else
                do_fsl_roi(fi_4D(k),Bdirname,ind(kind),ind(kind+1)-ind(kind)-1);
            end
        end
    end
    
    ffB0 = get_subdir_regex_files(p,'^theB0');
    ffBdir = get_subdir_regex_files(p,'^theBdir');
    
    if par.doB0mean
        ffB0 =  unzip_volume(ffB0);    ffB0 = get_subdir_regex_files(p,'^theB0');
        
        parameters.realign.to_first=1; parameters.realign.type='mean_and_reslice';
        j=do_realign(ffB0,parameters);spm_jobman('run',j)
        
        ffoneB0 =  get_subdir_regex_files(p,'^meantheB0_1.nii$',1)
        
        ffrBO = get_subdir_regex_files(p,'^rtheB0');
        par.sge=0;
        do_fsl_mean(ffrBO,fullfile(outdir,'B0_mean'),par)
        %do_delete(ffB0,0);
    end
    
    if par.dosusan
        cmd = sprintf('cd %s; susan meantheB0_1.nii %d 2 3 1 0 meanB0_susan%d',p,par.susan_noise,par.susan_noise)
        unix(cmd)
        
    end
    
    if par.do4D==1
        ffoneB0 = get_subdir_regex_files(p,sprintf('^meanB0_susan%d.nii',par.susan_noise),1);
        do_fsl_merge([ffoneB0 ffBdir],fullfile(outdir,[ff par.vol_sufix]));
        do_delete([ffB0 ffBdir],0)
    elseif par.do4D==2
        r_movefile(fi_4D(k),outdir,'link');
    end
    
    
    bval_d = bval;bval_d(ind)=[];
    bval_d = [bval(ind(1)), bval_d];
    
    bvec_d = bvec;bvec_d(:,ind)=[];
    bvec_d_fsl = [bvec(:,ind(1)), bvec_d];
    
    fid_trackvis = fopen(fullfile(outdir,[par.bvec par.vol_sufix]),'w');
    fprintf(fid_trackvis,'%f, %f, %f\n',bvec_d);
    fclose(fid_trackvis)
    
    fid_trackvis = fopen(fullfile(outdir,[par.bval par.vol_sufix]),'w');
    fprintf(fid_trackvis,'%f ',bval_d);
    fclose(fid_trackvis)
    
    fid_fsl = fopen(fullfile(outdir,[par.bvec ]),'w');
    for kd=1:3
        fprintf(fid_fsl,'%f ',bvec_d_fsl(kd,:));
        fprintf(fid_fsl,'\n');
    end
    fclose(fid_fsl)
    
    
    fid_fsl = fopen(fullfile(outdir,[par.bval ]),'w');
    fprintf(fid_fsl,'%d ',bval_d);
    fclose(fid_fsl)
    
end



