function transform_4D_multishell_to_singleshells(fi_4D,par)

if ~exist('par')
    par='';
end

defpar.bvals_values = [1000 2000 3000];
defpar.bvecs = '^bvecs$';
defpar.bvals = '^bvals$';
defpar.subdir='';

par = complet_struct(par,defpar);


for kf=1:length(fi_4D)
    
    [p,ff,e] = fileparts(fi_4D{kf});
    
    if strfind(ff,'.'),        [ppp ff e] = fileparts(ff);    end
        
    bvals = get_subdir_regex_files(p,par.bvals,1);
    bvecs = get_subdir_regex_files(p,par.bvecs,1);
    
    bval = load(bvals{1});   if size(bval,2)==1, bval=bval';end
    bvec = load(bvecs{1});   if size(bvec,2)==3, bvec=bvec';end

    
    indB0 = find(bval<60);
    totind = length(indB0);
    
    for k =1:length(par.bvals_values)
        indB{k} = find( bval>(par.bvals_values(k)-60) & bval<(par.bvals_values(k)+60) );
        totind = totind + length(indB{k});        
    end
    
    if length(bval) ~= totind
        error('missing bvalues find only a subset of %d instead of %d',totind,length(bval))        
    end
    
    outname = fullfile(p,'toutlesvolume3D');
    cmd = sprintf('fslsplit  %s %s -t',fi_4D{kf},outname);
    unix(cmd)
    
    fi3D = char(get_subdir_regex_files(p,'toutlesvolume3D',length(bval)));
    
    p0=p;
    
    for k =1:length(par.bvals_values)
            if ~isempty(par.subdir)
                p = r_mkdir({p0},sprintf('%s_B%d',par.subdir,par.bvals_values(k)));
                p = p{1};
            end

        outname = fullfile(p,[ff sprintf('_B%d',par.bvals_values(k))]);
        outnamebval = fullfile(p,sprintf('bval_B%d',par.bvals_values(k)));
        outnamebvec = fullfile(p,sprintf('bvec_B%d',par.bvals_values(k)));
        
        %B0 added only to the first
        if k==1
            select_ind = [indB0 indB{k}];
        else
            select_ind = indB{k};
        end
        
        do_fsl_merge(fi3D(select_ind,:),outname);        
        
        fid_fsl = fopen(outnamebvec,'w');
        for kd=1:3
            fprintf(fid_fsl,'%f ',bvec(kd,select_ind));
            fprintf(fid_fsl,'\n');
        end
        fclose(fid_fsl) ;       
        
        fid_fsl = fopen(outnamebval,'w');
        fprintf(fid_fsl,'%d ',bval(select_ind));
        fclose(fid_fsl);
                
    end
    
    outname = fullfile(p,[ff '_B0']);
    do_fsl_merge(fi3D([indB0 ],:),outname);        
    
    do_delete(fi3D,0)

end



