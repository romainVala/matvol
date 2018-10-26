
P = spm_select([1 Inf],'dir','Select directories of dicom files','','/network/lustre/iss01/cenir/raw/irm/dicom_raw/'); 

spm_defaults;

Dirnames = get_dir_recursif(P);

a=which('send_dicom_prisma.m');
p=fileparts(a);
pc = fullfile(p,'send_dicom_verio2.sh');

for k=1:length(Dirnames)
  fprintf('sending files for %s\n',Dirnames{k})
  unix( ['LD_LIBRARY_PATH= ' pc ' ' deblank(Dirnames{k}) '*.dic'] );
end  
