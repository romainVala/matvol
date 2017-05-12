function  matlabbatch = job_second_level_ttest(indir_stat,stat_dir,par)

if ~exist('par')
  par='';
end


%search for first level contrast
l = load(fullfile(indir_stat{1},'SPM.mat'));
icon = []; kkk=0;namecon={};

for kk=1:length(l.SPM.xCon)
    if  strcmp(l.SPM.xCon(kk).STAT,'T')
        kkk=kkk+1;
        icon(kkk) = kk;
        namecon{kkk} =  l.SPM.xCon(kk).name;
    end
end

nbjob = 1;
for nbcon = 1:length(namecon)
    
    stat_out = r_mkdir(stat_dir,namecon{nbcon});
    spmmat_f = {fullfile(stat_out{1},'SPM.mat')};
    
    conname = sprintf('con_%04d.nii',icon(nbcon));
    
    fcon = get_subdir_regex_files(indir_stat,conname,1);
    
    matlabbatch{nbjob}.spm.stats.factorial_design.dir = stat_out;
    matlabbatch{nbjob}.spm.stats.factorial_design.des.t1.scans = fcon';
    matlabbatch{nbjob}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'icfi', {}, 'icc', {});
    matlabbatch{nbjob}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'icfi', {}, 'icc', {});
    matlabbatch{nbjob}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{nbjob}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{nbjob}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{nbjob}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{nbjob}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{nbjob}.spm.stats.factorial_design.globalm.glonorm = 1;

    nbjob = nbjob+1;
    
    matlabbatch{nbjob}.spm.stats.fmri_est.spmmat(1) = spmmat_f;
    matlabbatch{nbjob}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{nbjob}.spm.stats.fmri_est.method.Classical = 1;
    
    nbjob = nbjob+1;
    
    matlabbatch{nbjob}.spm.stats.con.spmmat(1) = spmmat_f;
    matlabbatch{nbjob}.spm.stats.con.consess{1}.tcon.name = 'Positiv effect';
    matlabbatch{nbjob}.spm.stats.con.consess{1}.tcon.weights = 1;
    matlabbatch{nbjob}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{nbjob}.spm.stats.con.consess{2}.tcon.name = 'Negativ effect';
    matlabbatch{nbjob}.spm.stats.con.consess{2}.tcon.weights = -1;
    matlabbatch{nbjob}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
    matlabbatch{nbjob}.spm.stats.con.delete = 0;
    
    nbjob = nbjob+1;    

end
    
    