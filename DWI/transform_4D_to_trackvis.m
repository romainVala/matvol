function transform_4D_to_trackvis(fi_4D,par)

if ~exist('par')
    par='';
end
if ~exist('fi_4D'), fi_4D='';end

if ~isfield(par,'subdir'),  par.subdir = 'trackvis' ; end
if ~isfield(par,'vol_sufix'),  par.vol_sufix = '_trackvis' ; end
if ~isfield(par,'bvals'),  par.bvals = 'bvals'; end
if ~isfield(par,'bvecs'),  par.bvecs = 'bvecs'; end
if ~isfield(par,'do4D');  par.do4D = 1; end
if ~isfield(par,'doB0mean');  par.doB0mean = 1; end

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
        outdir = fullfile(p,par.subdir);
    end
    
    if ~exist(outdir), mkdir(outdir);  end
    
    bval = load(fullfile(p,par.bvals));
    bvec = load(fullfile(p,par.bvecs));
    
    ind = find(bval<50);
    
    if par.do4D==1
        for kind=1:length(ind)
            B0name = sprintf('theB0_%0.3d', kind);
            Bdirname = sprintf('theBdir_%0.3d',kind);
            
            do_fsl_roi(fi_4D(k),B0name,ind(kind)-1,1);
            
            if kind == length(ind)
                if ind(kind)<length(bval) %you have no b0 at the end
                    do_fsl_roi(fi_4D(k),Bdirname,ind(kind),length(bval)-ind(kind));
                end
                
            else
                do_fsl_roi(fi_4D(k),Bdirname,ind(kind),ind(kind+1)-ind(kind)-1);
            end
        end
        
        ffB0 = get_subdir_regex_files(p,'^theB0');
        ffBdir = get_subdir_regex_files(p,'^theBdir');
        
        do_fsl_merge([ffB0 ffBdir],fullfile(outdir,[ff par.vol_sufix]));
        
        if par.doB0mean
            do_fsl_mean(ffB0,fullfile(outdir,'B0_mean'))
        end
        
        do_delete([ffB0 ffBdir],0)
    elseif par.do4D==2
        r_movefile(fi_4D(k),outdir,'link');
    end
    
    
    bval_d = bval;bval_d(ind)=[];
    bval_d = [bval(ind), bval_d];
    
    bvec_d = bvec;bvec_d(:,ind)=[];
    %  bvec_d = [bvec(:,ind), bvec_d];
    
    fid_trackvis = fopen(fullfile(outdir,[par.bvecs par.vol_sufix]),'w');
    fprintf(fid_trackvis,'%f, %f, %f\n',bvec_d);
    fclose(fid_trackvis)
    
    fid_trackvis = fopen(fullfile(outdir,[par.bvals par.vol_sufix]),'w');
    fprintf(fid_trackvis,'%f ',bval_d);
    fclose(fid_trackvis)
    
end



