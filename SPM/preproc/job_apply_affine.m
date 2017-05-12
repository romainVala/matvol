function job = job_apply_affine(src,mat,fref,par)

if ~exist('fref'), fref={};end

if ~iscell(src),  src = cellstr(src);end
if ~iscell(fref),  ref = cellstr(ref)';end

if ~exist('par'),  par='';end

defpar.type = 'estimate';
defpar.interp = 0;
defpar.prefix = 'r';
defpar.prefixref = 'rmni';
defpar.sge = 0;

defpar.jobname='spm_coreg';
defpar.walltime = '00:30:00';

par = complet_struct(par,defpar);


job={};

for nbsuj = 1:length(src)
    
    if ischar(mat{nbsuj})
        l=load(mat{nbsuj});
        affmat = l.Affine;
    else
        affmat = mat{nbsuj};
    end
    
    matlabbatch{1}.spm.util.reorient.srcfiles = src(nbsuj);
    matlabbatch{1}.spm.util.reorient.transform.transM = affmat ;
    matlabbatch{1}.spm.util.reorient.prefix = par.prefix;
    
    fo = addprefixtofilenames(src(nbsuj),par.prefix);
    
    job(end+1) = matlabbatch;
    
    if ~isempty(fref)
        matlabbatch2{1}.spm.spatial.coreg.write.ref = fref(nbsuj);
        
        matlabbatch2{1}.spm.spatial.coreg.write.source = cellstr(char(fo));
        
        matlabbatch2{1}.spm.spatial.coreg.write.roptions.interp = par.interp;
        matlabbatch2{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
        matlabbatch2{1}.spm.spatial.coreg.write.roptions.mask = 0;
        matlabbatch2{1}.spm.spatial.coreg.write.roptions.prefix = par.prefixref;
        
        job(end+1) = matlabbatch2;
        
    end
    
    
    
end
if par.sge
    for k=1:length(job)
        j=job(k);
        cmd = {'spm_jobman(''run'',j)'};
        varfile = do_cmd_matlab_sge(cmd,par);
        save(varfile{1},'j');
    end
end