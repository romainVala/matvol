%  
%--------------------------------------------------------------------------
%          Cleaning and filtering rs-fMRI
%          Create Connectivity fonctional matrix (FCM)
%          Analyse FCM, ALFF & fALFF
%--------------------------------------------------------------------------


%
% This example assumes that you have already done the classic steps: 
% segmentation T1, slice timing , realign, topup, corregister, normalize and smoth. 
% To do it, See :"batch_preproc_rsfMRI.m or batch_preproc_exemple_new.m"
%  


% Working directory 
dir = '/network/iss/cenir/analyse/irm/users/salim.ouarab/data/crc_covid';



% Create un exam object named covid 
covid = exam(dir,'^2');               
covid.addSerie('fMRI_RS_MNI','fMRI');                  % rs-fMRI   
covid.addSerie('_T1_','anat');                         % T1       
covid.getSerie('fMRI').addVolume('^s_6wraf','sfmri');  % rs-fMRI smothed volume
covid.getSerie('fMRI').addVolume('^wraf','wfmri');     % rs-fMRI wraped volume
covid.getSerie('fMRI').arp('^rp.*txt','rp')            % rp file to fMRIrs serie (realign parameters)
covid.getSerie('anat').addVolume('^wre[35]_.*nii','mask') % MB and CSF eroded 

output  = r_mkdir(covid.getPath,'regressors/wreg');    % Create folder in each subject from covid exam


rs   = covid.getSerie('fMRI');   
anat = covid.getSerie('anat');    

% check rp file with threshold = 3mm (using FD)
% rs.getRP('rp').plot(3)     




%----------------- Create Design Matrix -----------------------------------
% Using TAPAS
% see : https://doi.org/10.1016/j.jneumeth.2016.10.019



clear par
par.physio   = 0;                  % No physio data
par.noiseROI = 1;                  % Use WM and CSF TS as regresseurs 
par.rp       = 1;                  % Use rp to create motion regressors

par.volume = rs.getVolume('sfmri') ;  % Use 
par.outdir = output;                  % output folder to save file multiple_regressors.txt 
par.TR     = 2.044;          
par.nSlice = 70;

par.noiseROI_mask         = anat.getVolume('mask');  % WM and CSF masks
par.noiseROI_volume       = rs.getVolume('wfmri');   % fMRI without smooth
par.noiseROI_thresholds   = [0.95 0.55];             % Keep voxels with tissu probabilty >= 95%
par.noiseROI_n_voxel_crop = 0;                       % ROIs are already eroded
par.noiseROI_n_components = 10;                      % Keep n PCA components


par.rp_file       = rs.grp;        % rp file txt
par.rp_order      = 24;            % Generate 24 motion regressors
par.rp_threshold  = 3;             % Use displacement threeshold: 3mm to creat stick regressor for  exceeding volume 
par.print_figures = 0;
par.sge           = 1;             % To create jobs for cluster
par.run           = 0;
par.jobname       = 'TAPAS';
job_physio_tapas( par );  

% run jobs in cluster

% Check Design Matrice (multiple_regressors file) and add it to exam
% rs.getVolume('sfmri').addRP(output,'^multi','RP2') /!\





%----------------- [clean & filter] & extract timeseries -----------------------------------------
% Using [SPM12 & FFT] & 1st eigen variate PCA



suj  = covid.getPath;
droi = gdir(suj,'masks_normalised');   % All masks are in this folder 

%-Select ROI :
% Use specific masks to  extract timeseries :
% Exemple of 2 networks (DAN and SMN)
% Get masks (Use regex to select them)
froi = get_subdir_regex_files(droi, '^VOI.*nii')  % All ROIs file of the two networks are start with 'VOI'

% Need mask name :

% 1) Get file name for only one subject
[~,fname] = get_parent_path(cellstr(froi{1}),1);  % All subjects have the same masks name.
mask_name(:,1) = fname;
disp(fname)   

% 2) Copy the result to any file txt or matlab script and edit the name to
% get abbreviation then copy the result (don't change the position):
% mask_name{:,2} = {paste abbreviation as char here};
mask_name(:,2) = {'L_MT'
    'L_a_intraprtal_sulcus'
    'L_front_eye'
    'L_motor_ctx'
    'L_p_intraparietal_sulcus'
    'L_pri_aud'
    'L_pri_vis'
    'R_MT'
    'R_a_intraprtal_sulcus'
    'R_front_eye'
    'R_motor_ctx'
    'R_p_intraprtal_sulcus'
    'R_pri_aud'
    'R_pri_vis'
    'SMA'}

% 3) Edit Again to get description and copy the result :
% mask_name{:,3} = {paste description as char here};
mask_name(:,3)  = {'Left MT mask'
    'Left anterior intraparietal sulcus mask'
    'Left front eye field mask'
    'Left motor cortex mask'
    'Left posterior intraparietal sulcus mask'
    'Left primary auditory mask'
    'Left primary visual mask'
    'Right MT mask'
    'Right anterior intraparietal sulcus mask'
    'Right front eye field mask'
    'Right motor cortex mask'
    'Right posterior intraparietal sulcus mask'
    'Right primary auditory mask'
    'Right primary visual mask'
    'Supplemental motor area mask'}



% Note : mask_name is cellstr array with 15 rows by 3 columns 
% Each row has : fname, abbreviation, description
% Each subject has 15 masks in the same order as mask_specific


dm =  gfile(output,'^multiple_regressors.txt')    % dm Design Matrice 

clear par
par.volume               = rs.getVolume('sfmri'); % smoothed rs-fMRI volume 
par.confound             = dm;
par.mask_threshold       = 0.8;
par.bandpass             = [0.01 0.1];            % Filter 
par.subdir               = 'rsfc';

par.roi_type.mask_specific.path = froi;                % Specific masks 
par.roi_type.mask_specific.info =  mask_name;          % names 


par.outname  = 'masks';   
par.mem      = '16G';                            
par.sge      = 1;
par.run      = 0;
par.jobname  = 'TimeSeries2';

TS = job_extract_timeseries(par);



%--------------------------------------------------------------------------


%----------------- Compute FCM using all ROIs -----------------------------
% Two subneworks : Dorsal attention network (DAN) and
% sensorimotor network (SMN)

% Use the description name to do it.

dan = {'Left_motor_cortex'
    'Left_primary_visual'
    'Left_primary_auditory'
    'Supplemental_motor_area'
    'Right_motor_cortex'
    'Right_primary_visual'
    'Right_primary_auditory'};

smn = {'Left_front_eye_field'
    'Left_posterior_intraparietal_sulcus'
    'Left_anterior_intraparietal_sulcus'
    'Left_MT'
    'Right_front_eye_field'
    'Right_posterior_intraparietal_sulcus'
    'Right_anterior_intraparietal_sulcus'
    'Right_MT'};

abb_dan = mask_name(contains(mask_name(:,1),dan),2) %  need just abbreviation column
abb_smn = mask_name(contains(mask_name(:,1),smn),2) %  


clear par
par.network.dan = abb_dan;
par.network.smn = abb_smn;

% Note that, if you don't have a subneworks, use the following function
% without "par"

TS      = job_timeseries_to_connectivity_matrix(TS,par)


% Visualize and check the connectivity matrixs 
guidata = plot_resting_state_connectivity_matrix(TS);


% get CM from TS data
[data, conn_result] = get_resting_state_connectivity_matrix(TS);





