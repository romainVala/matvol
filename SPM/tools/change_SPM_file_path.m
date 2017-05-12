function change_SPM_file_path(stat_dir,suj_dir)
if ischar(stat_dir)
stat_dir = {stat_dir};
end

if ischar(suj_dir)
suj_dir = {suj_dir}; 
end

if ~exist('suj_dir')
  suj_dir = get_parent_path(stat_dir,2);
end

cwd=pwd;

for k=1:length(stat_dir)

  fprintf('\nChanging %s SPM.mat\n',stat_dir{k})
  fprintf('new subject path is %s \n',suj_dir{k})
  
  cd(stat_dir{k})
  load 'SPM.mat';
  
  SPM.swd = pwd;
  
  SPM = mardo(SPM);
  
  SPM = cd_images(SPM, suj_dir{k});

  save_spm(SPM);

  clear SPM;

end

cd(cwd)
