
clear all
close all
clc


% VBM analysis using Dartel toolbox
%
% Segmentation MG, MB and CSF :
%              1) use SPM12 segmentation 
%                 or
%              2) use CAT12 segmentation 
% Dartel Template
% Dartel normalize 
% TIV
% stat



% get data

dir   = '/network/lustre/iss02/cenir/analyse/irm/users/salim.ouarab/data/crc_covid'
suj   = gdir(dir,'^2');
anat  = gdir(suj,'T1');
fanat = gfile(anat,'^s.*nii$');

% fanat = unzip_volume(fanat);    % if T1 is zipfile like nameT1.nii.gz  

% create folder vbm (just to optimize file organisation) 
r_mkdir(suj,'vbm');
vbm = gdir(suj,'vbm');

r_movefile(fanat,vbm,'copy');
fanat = gfile(vbm,'^s.*nii');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Use SPM12 segmentation 
% https://www.fil.ion.ucl.ac.uk/~john/misc/VBMclass15.pdf

clear par
par.GM   = [0 0 1 1];   % just native space(c1) and native space dartel import(rc1)
par.WM   = [0 0 1 1];   % just              c2  and                            rc2
par.CSF  = [0 0 1 0];   % just native space(c3)
par.bias = [0 0];       % don't save bias field and bias corrected, we don't need them
par.warp = [0 0];       % don't save deformation fields (y) and (iy), not needed
par.TPMC = [0 0 0] ;    % don't write other  Tissu Probability Map Classes

par.run          = 0;
par.sge          = 1;   % using cluster 
par.mem          = '16G';
par.jobname      = 'VBM_SEG_SPM';

% cd to job folder  
job_do_segment(fanat,par);   % Create jobs (as many as individual anatomical images) 

% Run jobs in cluster 
% This step generates c1, c2, c3, c4, c5, rc1, rc2 and ...seg8.mat files 

                    
%%%%%%%%%%%%%% Use CAT12 segmentation %%%%%%%%%%%%%%%%%%%%%
% Combine CAT2 and Dartel for VBM analysis
% 
% parameters for VBM 

clear par 

par.subfolder = 1;         % write in subfolder, just for better organisation (mri and report folders)

par.GM        = [0 0 1 2]; % index 3 = native_space (p1), value 1 = yes. // index 4 = native_space_dartel_import (rp1) value 2 = Affine
par.WM        = [0 0 1 2]; %                        (p2)                 //           rp2
par.CSF       = [0 0 1 0]; % just                  (p3)            
par.TPMC      = [0 0 0 0]; % just            (p4,p5,p6) don't need them for VBM

par.label     = [0 0 0] ;  % don't need label map 
par.bias      = [0 0 0] ;  % don't save the bias field corrected  + SANLM (global) T1
par.las       = [0 0 0] ;  % don't save the bias field corrected  + SANLM (local)  T1
par.warp      = [1 1]   ;  % warp field native to MNI (y_) / MNI to native(iy_) for normalize or de-normalize images 

par.run          = 0;
par.sge          = 1;   % using cluster 
par.mem          = '16G';
par.jobname      = 'VBM_SEG_CAT12';

job_do_segmentCAT12(fanat,par)

% generate : p0...p6, rp1, rp2, y and iy in mri folder 
% generate : report files and file.xml in report folder
% need rp1 and rp2 for next step and file xml to compute TIV 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Using Dartel toolbox to create template 
% Take rp1 and rp2 if using  cat12 segmentation 
% mri  = gdir(vbm,'^mri');
% frmg = gfile(mri,'^rp1');
% frmb = gfile(mri,'^rp2');

frmg = gfile(vbm,'^rc1');          % native space dartel import   
frmb = gfile(vbm,'^rc2');          % native space dartel import

clear par
par.run          = 0;
par.sge          = 1;   % using cluster 
par.mem          = '16G';
par.jobname      = 'Dartel_Template';

job_do_dartel_template(frmg,frmb,par);

% Run the one job
% generate u_ (flow field) for each suj and 6 templates in the first suj folder 



% Normalize MG 
% change folder if using CAT12 and take p1.*nii

template  = gfile(vbm(1),'Template_6');
ffield    = gfile(vbm,'^u.*nii');
mg        = gfile(vbm,'^c1.*nii');

clear par
par.preserve = 1;         % modulation [mw ]
par.fwhm     = [8 8 8];   % smooth     [smw ]
par.run          = 0;
par.sge          = 1;   % using cluster 
par.mem          = '16G';
par.jobname      = 'Dartel_Normalize_CAT12';

job_dartel_normalize(template,ffield,mg,par)


%%%% ===> Check normalized data with "chekreg"

%%%%%%% Compute TIV 
%%% If using SPM12 segmentation 

fseg = gfile(vbm,'seg8.*mat');

clear par
par.run          = 0;
par.sge          = 1;   % using cluster 
par.jobname      = 'TIV';

job_compute_TIV(fseg,par)


%%%  if using CAT12 segmentation 
dfile = gdir(vbm,'report');
fxml  = gfile(dfile,'^cat.*xml');

clear par
par.sge = 1;
par.jobname      = 'TIV_CAT12';

job_compute_TIV(fxml,par);
% genetrate txt file containes TIV 



%%%%%%% Statistical Analysis


% Note that, this is just an example on how to use the stats parameters for two samples t-test, 
% it depends on the assumption.
% For more details see :
%                  https://neuro-jena.github.io/cat12-help/#two_sample


%%% Get subjects informations : group, gender, age, TIV

% "info_covid_suj.csv" file contains informations about covid data set subjetcs
%  in this file :
% patients index [1 : 24]
% controls index [25 : 48]

fcsv = gfile(dir,'info_covid_suj.csv$');
info = readtable(fcsv{1});    

sujname = info.suj;
gender_str  = info.Gender;

age     = str2num(cell2mat(info.age));   % Convert str to number 

% gender : 

 % convert F to 0 and M to 1

gender  = contains(gender_str, 'M');   % sum(gender) is the number of male and sum(~gender) is the number of female


% TIV

sub  = gdir(dir,sujname)        % get subjects in the same order as age and gender  
dvbm = gdir(sub,'vbm'); 
% dtxt  = gdir(dvbm,'report');  % using CAT12 seg
% dvbm  = gdir(dvbm,'mri');     % using CAT12 seg
fseg = gfile(dvbm,'_seg8.*mat');         % or .txt in CAT12 segmentation folder 
% fseg = gfile(dtxt,'^tiv.*txt');
img1 = gfile(dvbm(1:24),'^smw.*nii');    %24 files (patients)
img2 = gfile(dvbm(25:end),'^smw.*nii');  %24 files (controls)

tiv =  getTIV(fseg);       


% 
dirStat = {'/network/lustre/iss02/cenir/analyse/irm/users/salim.ouarab/data/crc_covid/vbm'}
%dirStat = {'/network/lustre/iss02/cenir/analyse/irm/users/salim.ouarab/data/crc_covid/vbm_cat12_seg'}

clear par

par.cov_name = {'age','gender'};
par.age = age;
par.gender = gender;

par.th_masking = 0;      % not use absolute threshold masking 
par.use_imask  = 0 ;     % not use implicit mask
par.emask        = gfile('/network/lustre/iss02/cenir/software/irm/spm12/tpm','mask_ICV.nii');
par.gcalculation = 1;
par.gvalues      = tiv;  % Correction of TIV 

par.use_gms  = 0;
par.normalisation = 2;   % Using proportional scaling
par.rcontrast     = 0;   % don't result contrast for VBM

job_do_two_sample_ttest(dirStat,img1,img2,par)

% Getting Results for defining contrasts using SPM GUI