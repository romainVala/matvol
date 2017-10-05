function  dwi_remove_volume(fi_4D,outdir,skip_vol,par)
%index starting from 1

if ~exist('par'),  par=''; end

def_par.bval = 'bvals';
def_par.bvec = 'bvecs';

par = complet_struct(par,def_par);



for k=1:length(fi_4D)
    
    if ~exist(fullfile(outdir{k},'bvecs'),'file')
        
        [p,ffname,e] = fileparts(fi_4D{k});
        if iscell(par.bval)
            bval_f = par.bval;
            bvec_f = par.bvec;
        else
            
            bval_f = get_subdir_regex_files(p,par.bval,1);
            bvec_f = get_subdir_regex_files(p,par.bvec,1);
        end
        
        cmd = sprintf('fslsplit %s %s/vol -t',fi_4D{k},outdir{k});
        unix(cmd)
        ff = get_subdir_regex_files(outdir(k),'^vol');
        ff=cellstr(char(ff));
        do_delete(ff(skip_vol{k}),0)
        
        ff = get_subdir_regex_files(outdir(k),'^vol');
        
        do_fsl_merge(ff,fullfile(outdir{k},ffname));
        do_delete(ff,0)
        
        bval = load(bval_f{1});    bvec = load(bvec_f{1});
        bval(skip_vol{k}) = []; bvec(:,skip_vol{k})=[];
        
        
        fid = fopen(fullfile(outdir{k},'bvals'),'w');
        fprintf(fid,'%d ',bval);  fprintf(fid,'\n');  fclose(fid);
        
        fid = fopen(fullfile(outdir{k},'bvecs'),'w');
        for kk=1:3
            fprintf(fid,'%f ',bvec(kk,:));
            fprintf(fid,'\n');
        end
        fclose(fid);
        
    else
        fprintf('skiping %s because bvec file exist\n',fi_4D{k})
    end
end



