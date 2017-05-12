function  matlabbatch = job_do_one_sample_ttest(stat_dir,img,par)

if ~exist('par')
  par='';
end


if ~iscell(img)
  img = cellstr(img);
end

if ~iscell(stat_dir)
  stat_dir = cellstr(stat_dir);
end

if ~exist(stat_dir{1});mkdir(stat_dir{1});end

spmmat_f = fullfile(stat_dir{1},'SPM.mat');

matlabbatch{1}.spm.stats.factorial_design.dir = stat_dir;
%%
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = img;
%%
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;

matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 2;
%1=norm2=propor 3=ANCOVA

matlabbatch{2}.spm.stats.fmri_est.spmmat = {spmmat_f};
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;


matlabbatch{3}.spm.stats.con.spmmat = {spmmat_f};
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'positiv';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.convec = 1;
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'negative';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.convec = -1;
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 0;


matlabbatch{4}.spm.stats.results.spmmat = {spmmat_f};
matlabbatch{4}.spm.stats.results.conspec.titlestr = '';
matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
matlabbatch{4}.spm.stats.results.conspec.threshdesc = 'FWE';
matlabbatch{4}.spm.stats.results.conspec.thresh = 0.001;
matlabbatch{4}.spm.stats.results.conspec.extent = 10;
matlabbatch{4}.spm.stats.results.conspec.mask = struct('contrasts', {}, 'thresh', {}, 'mtype', {});
matlabbatch{4}.spm.stats.results.print = true;

