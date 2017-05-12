
fprintf('\nselect serie anat\n')
indira =  get_subdir_regex('/nasDicom/spm_raw/PROTO_INFLASEP');

[ps sera] = get_parent_path(indira);
[p suj] = get_parent_path(indira,2);

fprintf('\nselect serie the asl series\n')
indir =  get_subdir_regex(ps)
[ps ser] = get_parent_path(indir);

fprintf('\nselect an output directory\n')
outdir =  get_subdir_regex(pwd);


%first import the data
dirsuj = r_mkdir(outdir,suj);
dirasl = r_mkdir(dirsuj,[ser{1},'_flux'])
dirana = r_mkdir(dirsuj,[sera{1}])


fimg = get_subdir_regex_files(indir,'.*01.img$')
fhdr = get_subdir_regex_files(indir,'.*01.hdr$')
r_movefile(fimg,dirasl,'link')
r_movefile(fhdr,dirasl,'copy')

fa = get_subdir_regex_files(indira,'^s');
r_movefile(fa,dirana,'copy')

%preproc asl
ff = get_subdir_regex_files(dirasl,'^[fs]I.*img');ff=cellstr(char(ff));

par.realign.type = 'mean_and_reslice';
j=do_realign(ff,par);
spm_jobman('run',j);

ff = get_subdir_regex_files(dirasl,'^r[sf]I.*img')
j=job_smooth(ff)
spm_jobman('run',j);

%preproce anat
fa = get_subdir_regex_files(dirana,'^s.*img',1);
  fmean =  get_subdir_regex_files(dirasl,'^mean.*img',1);

j = job_coregister(fa,fmean,'')
spm_jobman('run',j);

par.output_name='T1_bet';par.frac = 0.5 ;
do_fsl_bet(fa,par)
mask = get_subdir_regex_files(dirana,'T1_bet_mask')
ff=cellstr(char(ff));
fmask =   do_fsl_reslice(mask(1),ff(1),'rasl')
fmask = do_fsl_bin(fmask,'',0.5);
fmask=unzip_volume(fmask)


%a séquence est "pseudo-continuous" (pCASL) car le tagging est presque continu mais en fait provient d'un train de pulses RF.
%J'ai demandé des explications sur l'implémentation et il semble que ce soit fait ainsi :
%The RF pulse is duration is 500us, plus 2*20us of ramp, and interspace between pulses of 900 us (RF gap).
% Each RF block has 20 pulses. With 60 RF blocks,
%Tagging Duration = (540 + 900)*20 *60 = 1728000, soit environ 1.73 secondes



aslfiles1 = char(get_subdir_regex_files(dirasl,'^sr[fs].*img'));
%aslfiles1 = char(f)
numSess = 1;
fileOrder = 3;
CBFmodel = 'Wang';
seqParams = struct('M0',{''},'useM0mean',0,'postTagDelay',0.9,'acqOrder',1,'tagDur',1.5,'TR',3)
seqParams = struct('M0',{''},'useM0mean',0,'postTagDelay',1.25,'acqOrder',1,'tagDur',1.73,'TR',3)
M0file = '';
doAddition = 0;
outputfilename = 'sM0_mask_flow4D.nii';
maskfile = char(fmask);% '';
save3Dfiles = 0;
subtractionType = 0;
dataType = 16;
fROI = ''; % '/home/romain/images5/ASL/2012_03_05_INFLASEP_Pilote04/S02_t1_weighted_sagittal/c1asl_bin.nii';
dont_recompute_subtraction = 1;
rmv_start_imgs = 0;

[hdr4D1 hdr_qt1] = util_compute_asl_subtract(aslfiles1,numSess,fileOrder,CBFmodel,seqParams,M0file,doAddition,outputfilename,maskfile,save3Dfiles,subtractionType,dataType,fROI,dont_recompute_subtraction,rmv_start_imgs)



