% prendre les images dans '/export/dataCENIR/dicom/nifti_raw/VERIO_PAS_AVC'
% et les coller dans '/servernas/images4/rosso/PAS_AVC4D'


chemin={'/servernas/images4/rosso/PAS_AVC4D'}
suj = get_subdir_regex(chemin)
%ou
suj = get_subdir_regex(chemin,'^2'); %to get all subdir that start with 2
%to see the content
char(suj)


%functional and anatomic subdir
par.dfonc_reg='EP2D.*[DG]$';
par.dfonc_reg_oposit_phase = 'ref_PA$';
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

ff=get_subdir_regex_files(anat,'^c[123]',3);
fo=addsuffixtofilenames(anat,'/mask_brain');
do_fsl_add(ff,fo)
fm=get_subdir_regex_files(anat,'^mask_b',1); fanat=get_subdir_regex_files(anat,'^s.*nii',1);
fo = addprefixtofilenames(fanat,'brain_');
do_fsl_mult(concat_cell(fm,fanat),fo);



%puis fait le lien symbolique du rep anat

%get subdir

dfonc = get_subdir_regex_multi(suj,par.dfonc_reg)
dfonc_op = get_subdir_regex_multi(suj,par.dfonc_reg_oposit_phase)
dfoncall = get_subdir_regex_multi(suj,{par.dfonc_reg,par.dfonc_reg_oposit_phase })
anat = get_subdir_regex_one(suj,par.danat_reg) %should be no warning

%slice timing
par.slice_order = 'sequential_ascending';
par.reference_slice='middel'; 

j = job_slice_timing(dfonc,par)

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




%%%%%%%%first level
sta=r_mkdir(suj,'stat')
st =r_mkdir(sta,'modelBloc')

onset{1}(1).name = 'control_diff';  onset{1}(1).onset = 0:48:167 ;  onset{1}(1).duration = ones(1,4)*24;
onset{1}(2).name = 'rappel_diff';   onset{1}(2).onset = 24:48:167 ; onset{1}(2).duration = ones(1,3)*24;

onset{2}(1).name = 'control_flu';   onset{2}(1).onset =  0:60:209 ;  onset{2}(1).duration = ones(1,4)*30;
onset{2}(2).name = 'fluence';       onset{2}(2).onset = 30:60:209; onset{2}(2).duration = ones(1,3)*30;

onset{3}(1).name = 'control_enco';  onset{3}(1).onset =  0:72:251;  onset{3}(1).duration = ones(1,4)*36;
onset{3}(2).name = 'encodage';      onset{3}(2).onset = 36:72:251; onset{3}(2).duration = ones(1,3)*36;

onset{4}(1).name = 'control_imm';  onset{4}(1).onset = 0:48:167  ;  onset{4}(1).duration = ones(1,4)*24;
onset{4}(2).name = 'rappel_imm';   onset{4}(2).onset = 24:48:167 ; onset{4}(2).duration = ones(1,3)*24;

j = job_first_level12(dfonc,st,onset,par)


%odir = get_subdir_regex(suj,'onset')
%f1 = get_subdir_regex_files(odir,'modelO.*A1',1);f2 = get_subdir_regex_files(odir,'modelO.*D2',1);f3 = get_subdir_regex_files(odir,'modelO.*A3',1);f4 = get_subdir_regex_files(odir,'modelO.*D4',1);
%fons = concat_cell(f1,f2,f3,f4);
% j = job_first_level12(dfonc,st,fons,par)

par.file_reg = '^sws'


spm_jobman('run',j)


fspm = get_subdir_regex_files(st,'SPM',1)
j = job_first_level12_estimate(fspm)

contrast.values = {[-1 1 ], [0 0 -1 1],[0 0 0 0 -1 1],[0 0 0 0 0 0 -1 1] };
contrast.names = {'rappel_diff','fluence','encodage', 'rappel_imm'};
contrast.types = {'T','T','T','T'};
par.delete_previous=1
j = job_first_level12_contrast(fspm,contrast,par)



%second level

%que les control !
%suj = get_subdir_regex(pwd,'^2')

st = get_subdir_regex(suj,'stat','modelB')

j = job_second_level_ttest(st,dirout)


