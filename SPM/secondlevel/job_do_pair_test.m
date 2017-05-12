function  matlabbatch = job_do_pair_test(stat_dir,img1,img2,par)

if ~exist('par')
  par='';
end

if ~isfield(par,'type')
  par.type = 1 ; % 1 = '2ttest'; 2= pair_ttest
end

img1 = cellstr(char(img1));
img2 = cellstr(char(img2));

if isempty(stat_dir)
   stat_dir = get_subdir_regex();
end

if ~iscell(stat_dir)
  stat_dir = cellstr(stat_dir);
end

if ~exist(stat_dir{1});mkdir(stat_dir{1});end

spmmat_f = fullfile(stat_dir{1},'SPM.mat');

matlabbatch{1}.spm.stats.factorial_design.dir = stat_dir;
for k=1:length(img1)
	matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(k).scans = { img1{k},img2{k}};
end

matlabbatch{1}.spm.stats.factorial_design.des.pt.gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.pt.ancova = 0;
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

matlabbatch{2}.spm.stats.fmri_est.spmmat = {spmmat_f};
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;


matlabbatch{3}.spm.stats.con.spmmat = {spmmat_f};
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Groupe1 > Groupe2';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.convec = [1 -1];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'Groupe2 > Groupe1';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.convec = [-1 1];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 0;

matlabbatch{4}.spm.stats.results.spmmat = {spmmat_f};
matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'Groupe1 > Groupe2';
matlabbatch{4}.spm.stats.results.conspec(1).contrasts = 1;
matlabbatch{4}.spm.stats.results.conspec(1).threshdesc = 'FWE';
matlabbatch{4}.spm.stats.results.conspec(1).thresh = 0.001;
matlabbatch{4}.spm.stats.results.conspec(1).extent = 10;
matlabbatch{4}.spm.stats.results.conspec(1).mask = struct('contrasts', {}, 'thresh', {}, 'mtype', {});

matlabbatch{4}.spm.stats.results.conspec(2).titlestr = 'Groupe2 > Groupe1';
matlabbatch{4}.spm.stats.results.conspec(2).contrasts = 1;
matlabbatch{4}.spm.stats.results.conspec(2).threshdesc = 'FWE';
matlabbatch{4}.spm.stats.results.conspec(2).thresh = 0.001;
matlabbatch{4}.spm.stats.results.conspec(2).extent = 10;
matlabbatch{4}.spm.stats.results.conspec(2).mask = struct('contrasts', {}, 'thresh', {}, 'mtype', {});

matlabbatch{4}.spm.stats.results.print = true;
