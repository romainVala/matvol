% prendre les images dans '/export/dataCENIR/dicom/nifti_raw/VERIO_PAS_AVC'
% et les coller dans '/servernas/images4/rosso/PAS_AVC4D'


chemin={'/servernas/images4/rosso/PAS_AVC4D'}
suj = gdir(chemin)
%ou
suj = gdir(chemin,'^2'); %to get all subdir that start with 2
%to see the content
char(suj)


%functional and anatomic subdir
par.dfonc_reg='ep2d.*[123456789]$';
par.dfonc_reg_oposit_phase = 'REFBLIP$';
par.danat_reg='t1mpr';

%for the preprocessing : Volume selecytion
par.anat_file_reg  = '^s.*nii'; %le nom generique du volume pour l'anat
par.file_reg  = '^f.*nii'; %le nom generique du volume pour les fonctionel

%par.TR = 2.1; %for slice timing
par.run=1;par.display=0; 



%anat segment
anat = gdir(suj,par.danat_reg)
fanat = gfile(anat,par.anat_file_reg,1)

j = job_do_segment(fanat)

%apply normalize on anat
fy = gfile(anat,'^y',1)
fanat = gfile(anat,'^ms',1)
j=job_apply_normalize(fy,fanat,par)


%anat brain extract you need to have fsl and mrtrix in your path

do_fsl_mask_from_spm_segment(fanat)


%puis fait le lien symbolique du rep anat

%get subdir

dfonc = get_subdir_regex_multi(suj,par.dfonc_reg)
dfonc_op = get_subdir_regex_multi(suj,par.dfonc_reg_oposit_phase)
dfoncall = get_subdir_regex_multi(suj,{par.dfonc_reg,par.dfonc_reg_oposit_phase })
anat = get_subdir_regex_one(suj,par.danat_reg) %should be no warning


%slice timing
%par.slice_order = 'sequential_ascending';
%par.reference_slice='middel'; 

%j = job_slice_timing(dfonc,par)

%realign and reslice
par.file_reg = '^f.*nii'; par.type = 'estimate_and_reslice';
j = job_realign(dfonc,par)

%realign and reslice opposite phase
par.file_reg = '^f.*nii'; par.type = 'estimate_and_reslice';
j = job_realign(dfonc_op,par)

%topup and unwarp
par.file_reg = {'^rf.*nii','^rf.*nii$'}; par.sge=0;
do_topup_unwarp_4D(dfoncall,par)

%coregister mean fonc on brain_anat
fanat = gfile(anat,'^brain.*nii$',1)

par.type = 'estimate';
for nbs=1:length(suj)
    fmean(nbs) = gfile(dfonc{nbs}(1),'^utmeanf');
end

fo = gfile(dfonc,'^utrf.*nii',1)
j=job_coregister(fmean,fanat,fo,par)

%apply normalize
fy = gfile(anat,'^y',1)
j=job_apply_normalize(fy,fo,par)

%smooth the data
ffonc = gfile(dfonc,'^wutrf')
par.smooth = [8 8 8];
j=job_smooth(ffonc,par);



