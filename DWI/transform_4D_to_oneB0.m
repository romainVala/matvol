function varargout = transform_4D_to_oneB0(fi_4D,par)

if ~exist('fi_4D'), fi_4D='';end

if ~exist('par'),  par=''; end

def_par.bval = 'bvals';
def_par.bvec = 'bvecs';
def_par.dosusan = 0;
def_par.do_delete=1;
def_par.susan_noise = 100;
def_par.do_delete=1;
def_par.do_realign = 0;
def_par.B0_prefix = 'B0_mean';
def_par.B04D_prefix = 'B0_4D';
def_par.dwi4D_prefix = 'dwi_4D';
def_par.skip_vol='';
def_par.B0_name='';
def_par.b0thr = 50;
def_par.doDWIvol = 0;

par = complet_struct(par,def_par);

if nargin ==0 && nargout==1
    varargout{1} = par;
    return
end

    

if isempty(fi_4D)
    fi_4D = spm_select(inf,'.*','select 4D data','',pwd);fi_4D= cellstr(fi_4D);
end

for k=1:length(fi_4D)
    
    [p,ff,e] = fileparts(fi_4D{k});
    if iscell(par.bval)
        bval_f = par.bval;
        bvec_f = par.bvec;
    else
        
        bval_f = get_subdir_regex_files(p,par.bval,1);
        bvec_f = get_subdir_regex_files(p,par.bvec,1);
    end
    
    if ~isempty(par.B0_name)
        fo = par.B0_name{k};
        [p ff] = fileparts(fo);
        fo4D = addprefixtofilenames(fo,par.B04D_prefix);
    else
        fo = addprefixtofilenames(fi_4D{k},par.B0_prefix);
        fo4D = addprefixtofilenames(fi_4D{k},par.B04D_prefix);
    end
        
%     if findstr(ff,'.')
%         [ppp ff e] = fileparts(ff);
%     end

    if length(bval_f)>1
        bval = load(bval_f{k});    bvec = load(bvec_f{k});
    else
        bval = load(bval_f{1});    bvec = load(bvec_f{1});
    end
        
    if par.skip_vol
        bval(par.skip_vol) = []; bvec(:,par.skip_vol)=[];
    end

    if size(bval,2)==1, bval=bval';end
    if size(bvec,2)==3, bvec=bvec';end
    
    %ind = find(bval==0);
    %if isempty(ind)
        ind = find(bval<par.b0thr);
    %    bval(ind)=0;
    %end
    
    for kind=1:length(ind)
        prefixx = sprintf('theB0_%.3d', kind);
        B0name = { addprefixtofilenames(fo,prefixx)};
        do_fsl_roi(fi_4D(k),B0name,ind(kind)-1,1);
    end
    
    ffB0 = get_subdir_regex_files(p,'^theB0');    
    
    if par.do_realign
        
        ffB0 =  unzip_volume(ffB0);    ffB0 = get_subdir_regex_files(p,'^theB0');
        
        parameters.realign.to_first=1; parameters.realign.type='mean_and_reslice';
        j=do_realign(ffB0,parameters);spm_jobman('run',j)
        
        ffoneB0 =  get_subdir_regex_files(p,'^meantheB0_1.nii$',1)
        fo = change_file_extension(fo,'.nii')
        r_movefile(ffoneB0,fo,'move')
    else
        
        par.sge=0;
        do_fsl_mean(ffB0,fo,par);
        do_fsl_merge(ffB0,fo4D,par);
    end
    
    if par.do_delete
        ff =get_subdir_regex_files(p,'theB0');
        do_delete(ff,0)
    end
    %do_delete(ffB0,0);
    
    if par.dosusan
        cmd = sprintf('cd %s; susan meantheB0_1.nii %d 2 3 1 0 meanB0_susan%d',p,par.susan_noise,par.susan_noise)
        unix(cmd)
        
    end
    
    if par.doDWIvol
        outname = fullfile(p,'toutlesvolume3D');
        cmd = sprintf('fslsplit  %s %s -t',fi_4D{k},outname);
        unix(cmd)
        
        inddwi = find(bval > par.b0thr);
        
        fi3D = get_subdir_regex_files(p,'toutlesvolume3D',length(bval));
        fi3D = cellstr(char(fi3D));
        fo4D = addprefixtofilenames(fi_4D{k},par.dwi4D_prefix);

        do_fsl_merge(fi3D(inddwi),fo4D);        
        do_delete(fi3D,0)
    end
    
    Fout{k}=fo4D;
    
end
varargout{1} =Fout;


