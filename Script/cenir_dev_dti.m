 
ss=get_subdir_regex('/nasDicom/spm_raw/PROTO_CENIR_DEV');
outdir = '/icm/cluster_home/romain.valabregue/datas/dti/cenir_dev1';
import_cenir_suj(ss,outdir) 


suj = get_subdir_regex(pwd,'DEV')
anat=get_subdir_regex(suj,'T1')
fanat = get_subdir_regex_files(anat,'^s.*nii$',1)
dti = get_subdir_regex(suj,'DTI')
fdti = get_subdir_regex_files(dti,'^4D_dti_eddycor_unw.*nii',1)
fmdir = get_subdir_regex_multi(suj,'B0MAP')
roi = get_subdir_regex(suj,'roimni')
mrdir = get_subdir_regex(dti,'mrtrix');

%one anat per DTI 
sujd = get_parent_path(dti)
fmdir = get_subdir_regex_multi(sujd,'B0MAP')
anat=get_subdir_regex(sujd,'T1')
fanat = get_subdir_regex_files(anat,'^s.*nii$',1)
roi = get_subdir_regex(sujd,'roimni')


%%%freesurfer
par.free_sujdir = '/export/home/romain.valabregue/datas/dti/cenir_dev1/freesurfer'; %par.free_cmd = 'freesurfercrop';
par.version_path = 'source /export/home/romain.valabregue/bin/freesurfer5 ';
par.sge_queu = 'long';par.walltime = '24:00:00';

fanat_suj{1} = char([fanat(1),fanat(4)]);par.sujname{1} = 'Pilote01';fanat_suj{2} = char([fanat(2),fanat(3)]);par.sujname{2} = 'Pilote02';
fanat_suj{3} = char([fanat(5),fanat(6)]);par.sujname{3} = 'Pilote03';fanat_suj{4} = char([fanat(7),fanat(8)]);par.sujname{4} = 'Pilote04';
do_freesurfer(fanat_suj,par)

%copy the result
[pp sujn]=get_parent_path(suj); for k=1:length(sujn), sfo{k} = sujn{k}(29:36);end
sujf = get_subdir_regex_one(par.free_sujdir,sfo,'mri')
volf=get_subdir_regex_files(sujf,{'T1.mgz','aparc.a2009s','^aseg.mgz','wmparc.mgz'},4);
anatf = r_mkdir(suj,'anat_free')
r_movefile(volf,anatf,'link')
ff=get_subdir_regex_files(anatf,'mgz')
convert_mgz2nii(ff);
%coreg to the T1
fanatf=get_subdir_regex_files(anatf,'T1.nii',1)
fo = get_subdir_regex_files(anatf,'^[aw].*nii',3)
j=job_coregister(fanatf,fanat,fo)

%%ANAT
%vbm8
for k=1:length(fanat),    j(k) = job_vbm8(fanat(k)); end
par.sge_queu='matlab_nodes';
do_cmd_jobmam_sge(j,par)

%roi mni
froimni = get_subdir_regex_files('//export/home/romain.valabregue/datas/dti/cenir_dev1/roimni','.*nii')
r_movefile(char(froimni),roi,'link')
flowfield_inv = get_subdir_regex_files(anat,'^iy',1);
froi = get_subdir_regex_files(roi,'.*nii')
par.interp=1; j = job_vbm8_create_wraped(flowfield_inv,froi,par);
spm_jobman('interactive',j);

p1=get_subdir_regex_files(anat,'^p.*nii',3)
for k=1:length(p1)
    fp1 = p1{k}(1,:);    fp2 = p1{k}(2,:);    fp3 = p1{k}(3,:);
    fo = addsuffixtofilenames(anat,'/bm_mask.nii');
    fo2 = addsuffixtofilenames(anat,'/white_mask.nii');
    cmd = sprintf('c3d %s %s %s -add -add -binarize %s -threshold 0.000001 inf -1 0 -add -clip 0 1 -o %s',fp1,fp2,fp3,fp3,fo{k});
    cmd = sprintf('%s\n c3d %s -threshold 1 1 1 0 -o %s\n',cmd,fp2,fo2{k})
    job{k} = cmd;
end

%%%preproce DTI
par.sge=-1;
[j fmask] = do_fsl_bet(fdti,par);
par.sge=1;par.sge_queu='long'
[j fdti] = do_fsl_dtieddycor(fdti,par,j);

par.sge_queu='long';
do_fsl_dtiunwarp(fdti,fmdir,par)

%%coreg DTI
%extract B0
transform_4D_to_oneB0(fdti)
ff=get_subdir_regex_files(dti,'unwarp');
unzip_volume(ff)
fbo=get_subdir_regex_files(dti,'B0_mean.*unw',1)
j=job_coregister(fbo,fanat,fdti)

do_fsl_dtifit(fdti,par)
process_mrtrix(fdti)

%trackto
sd = get_subdir_regex_files(mrdir,'CSD',1)
par.mask = get_subdir_regex_files(anat,'^bm',1);
fseed = get_subdir_regex_files(anat,'white',1);
par.track_num=1500000; par.track_maxnum = par.track_num; par.sge_queu='long';
process_mrtrix_trackto(sd,fseed,par)

clear par; par.sge_queu='long';
ft = get_subdir_regex_files(mrdir,'seedwhite_mask.trk',1);
par.roi_include = get_subdir_regex_files(roi,{'wmesG.nii','wm1g.nii'},2);par.roi_exclude = get_subdir_regex_files(roi,{'wsag.nii'},1) ;
par.track_name = 'CST_G';
mrtrix_filter_trackt(ft,par)

par.roi_include = get_subdir_regex_files(roi,{'wtriG.nii','wtriD.nii'},2);par.roi_exclude = get_subdir_regex_files(roi,{'wcoroCP.nii'},1) ;
par.track_name = 'CC_tri_exclu';
mrtrix_filter_trackt(ft,par)

par.roi_include = get_subdir_regex_files(roi,{'wtriG.nii','wtsupG.nii'},2);par.roi_exclude = get_subdir_regex_files(roi,{'wheschlG.nii','woprolG.nii','wsag.nii','wceG2.nii','wteg.nii','wcoro_ARC.nii'},6) ;
par.track_name = 'ARC_G';
mrtrix_filter_trackt(ft,par)

clear par; par.sge_queu='long';
par.roi_include = get_subdir_regex_files(roi,{'wmesG.nii'},1)
par.track_name = 'CST_mesG_all';
mrtrix_filter_trackt(ft,par)

%%VBM FA
flowfield = get_subdir_regex_files(anat,'^y',1);
par.interp=1; j = job_vbm8_create_wraped(flowfield,ffa,par);
spm_jobman('interactive',j);
ffaw=get_subdir_regex_files(dti,'^w4D.*FA',1)
j=job_smooth(ffaw)
%%STATS

ft = get_subdir_regex_files(mrdir,'^[CA].*trk',4)
ffa = get_subdir_regex_files(dti,'^4D.*FA',1)
mrtrix_tracks2prob(ft,fanat,par)
ft_prob = get_subdir_regex_files(mrdir,'^A.*_prob.nii',1);

do_fsl_reslice(ffa,ft_prob,struct('prefix','rT1mr_'))

par.wm = get_subdir_regex_files(dti,'rT1mr',1)
par.wm_name={'FA'};

dti_names={'VERIO_DTI_1500_65dir_2iso_TE83_ip2_NoGating','VERIO_DTI_1500_65dir_2iso_TE83_ip3_NoGating',...
    'VERIO_DTI_1000_65dir_2iso_TE77_ip3_NoGating','VERIO_DTI_1500_65dir_2iso_TE85_TR690_ip3_Gating'...
    'TRIO_DTI_1500_65dir_2iso_TE91_ip2_NoGating','TRIO_DTI_1500_65dir_2iso_TE87_ip3_NoGating',...
    'TRIO_DTI_1000_65dir_2iso_TE87_ip3_NoGating','TRIO_DTI_3000_65dir_2iso_TE111_ip3_NoGating',...
    'TRIO_DTI_1500_65dir_2iso_TE88_TR690_ip3_Gating'}

for k=1:length(dti_names)
    dti = get_subdir_regex(suj,dti_names(k));
    sujd = get_parent_path(dti);
    mrdir = get_subdir_regex(dti,'mrtrix');

    ft = get_subdir_regex_files(mrdir,'^[CA].*trk',4);
    
    clear cout par; par.wm = get_subdir_regex_files(dti,'rT1mr',1);    par.wm_name={'FA'};
    
    cout.pool=dti_names{k};
    [pp cout.suj] = get_parent_path(sujd);
    
    C(k) = get_val_from_mrtrix_track(ft,par,cout)

end

 write_res_to_csv(C,'toto.csv')
