
nbjobs = length(jobs) + 1;

psuj = fileparts(params.subjectdir); [p,sujname] = fileparts(psuj);
    
if isfield(params,'free_sujname_sufix')
  ssufix=params.free_sujname_sufix;
else
  ssufix='';
end

if strcmp(params.free_sujdir(1),'/')
  freesujdir = params.free_sujdir;
else
  freesujdir = fullfile(psuj,params.free_sujdir);
end
if ~exist(freesujdir)
  mkdir (freesujdir)
end


sujfree_dir = fullfile(freesujdir,sujname);

if exist(sujfree_dir)
  fprintf('Skiping suj %s because freesurfer dir exist :%s \n',sujname,freesujdir)
  jobs{nbjobs}.free_cmd = '';
  
else
  

  switch action 
    case 'freesurferall'
      cmd = sprintf('recon-all -i %s -s %s -sd %s -all -qcache ',anat,[sujname ssufix],freesujdir);
      
    case 'freesurfer'
      cmd = sprintf('recon-all -i %s -s %s -sd %s -all ',anat,[sujname ssufix],freesujdir);
       
    case 'freesurfercrop'
      cmd = sprintf('recon-all -i %s -s %s -cw256 -sd %s -all ',anat,[sujname ssufix],freesujdir);
      
     
    case 'freesurfer_qcache'
      cmd = sprintf('recon-all  -s %s -sd %s -qcache ',[sujname ssufix],freesujdir);

  end


  jobs{nbjobs}.free_cmd = cmd;

end


%recon-all -i S02_T1W/
%s410_568_432-0002-00001-000208-01.nii -i  S03_T1W_REPEAT/s410_568_432-0003-00001-000208-01.nii  -s T30_2011_06_24_410_568_432 -sd ~/data/freesurfer -all  -cw256 