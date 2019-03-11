% prendre les images dans '/export/dataCENIR/dicom/nifti_raw/VERIO_PAS_AVC'
% et les coller dans '/servernas/images4/rosso/PAS_AVC4D'


addpath(genpath('/export/data/opt/CENIR/matvol_git'))

chemin={'/scratch/MBB/emmanuelle.bioud/Nifti4D/'}
sujnum = getenv('SLURM_ARRAY_TASK_ID')
sujnumstr = sprintf('%.2d$',sujnum)

suj = get_subdir_regex(chemin,sujnumstr); %to get all subdir that start with 2
%to see the content
char(suj)


%functional and anatomic subdir
par.dfonc_reg='RUN[1234567890]$';
par.dfonc_reg_oposit_phase = 'BLIP$';
par.danat_reg='t1mpr';

%for the preprocessing : Volume selecytion
par.anat_file_reg  = '^s.*nii'; %le nom generique du volume pour l'anat
par.file_reg  = '^f.*nii'; %le nom generique du volume pour les fonctionel

par.TR = 2.1; %for slice timing
par.run=1;par.display=0; 



%anat segment
anat = get_subdir_regex(suj,par.danat_reg)
fanat = get_subdir_regex_files(anat,par.anat_file_reg,1)

par.GM   = [1 0 1 0]; % Unmodulated / modulated / native_space dartel / import
par.WM   = [1 0 1 0]; 
j = job_do_segment(fanat,par)

%apply normalize on anat
fy = get_subdir_regex_files(anat,'^y',1)
fanat = get_subdir_regex_files(anat,'^ms',1)
j=job_apply_normalize(fy,fanat,par)


%anat brain extract
do_fsl_mask_from_spm_segment(fanat)


%puis fait le lien symbolique du rep anat

%get subdir

dfonc = get_subdir_regex_multi(suj,par.dfonc_reg)
dfonc_op = get_subdir_regex_multi(suj,par.dfonc_reg_oposit_phase)
dfoncall = get_subdir_regex_multi(suj,{par.dfonc_reg,par.dfonc_reg_oposit_phase })
anat = get_subdir_regex_one(suj,par.danat_reg) %should be no warning

%slice timing
% par.slice_order = 'sequential_ascending';
% par.reference_slice='middel'; 
% 
% j = job_slice_timing(dfonc,par)

%realign and reslice
par.file_reg = '^af.*nii'; par.type = 'estimate_and_reslice';
j = job_realign(dfonc,par)

%realign and reslice opposite phase
par.file_reg = '^f.*nii'; par.type = 'estimate_and_reslice';
j = job_realign(dfonc_op,par)

%topup and unwarp
par.file_reg = {'^raf.*nii','^rf.*nii$'}; par.sge=0;
do_topup_unwarp_4D(dfoncall,par)

%coregister mean fonc on brain_anat
fanat = get_subdir_regex_files(anat,'^brain.*nii$',1)

par.type = 'estimate';
for nbs=1:length(suj)
    fmean(nbs) = get_subdir_regex_files(dfonc{nbs}(1),'^utmeanaf');
end

fo = get_subdir_regex_files(dfonc,'^utraf.*nii',1)
j=job_coregister(fmean,fanat,fo,par)

%apply normalize
fy = get_subdir_regex_files(anat,'^y',1)
j=job_apply_normalize(fy,fo,par)

%smooth the data
ffonc = get_subdir_regex_files(dfonc,'^wutraf')
par.smooth = [8 8 8];
j=job_smooth(ffonc,par);



