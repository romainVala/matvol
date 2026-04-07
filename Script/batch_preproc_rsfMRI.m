
%--------------------------------------------------------------------------
%
%                           Preprocessing 
%                       Resting state fMRI DATA
%
%--------------------------------------------------------------------------





% We use CAT12 for anatomical preprocessing, SPM12 for rs-fMRI preprocessing, 
%    and mrview for image visualization.



%% First, copy the data to your working directory using Matvol's 
% 'r_movefile' function.


% Data directory 
dataDir = '/network/iss/cenir/analyse/irm/users/salim.ouarab/data/DataTP_fMRIrs';
suj     = gdir(dataDir,'^2')           % 4 subjects 

% Working directory
% /!\ Replace this path with the path to your own workspace.
dir     = '/network/iss/cenir/analyse/irm/users/salim.ouarab/data/DataTP_fMRIrs/data';

% Using cluster 
clear par
par.sge     = 1;                  
par.jobname = 'COPYDATA';
r_movefile(suj,dir,'copy',par)

% Now, run the jobs on the cluster 
% Visually check the folders and subfolders you have copied 

%--------------------------------------------------------------------------


% Get subjects from working directory

dir = '/network/iss/cenir/analyse/irm/users/salim.ouarab/data/DataTP_fMRIrs/data';
suj = gdir(dir,'^2')          % 4 subjects are copied  


% Check data organization 



%--------------------------------------------------------------------------
%                       Step 1
%                 Sgmentation T1 image 
%                     using CAT12
%                 ---------------------


danat =  gdir(suj,'T1');     
fanat =  gfile(danat,'^s');

clear par
par.subfolder    = 1;         % write in subfolder
par.run          = 0;
par.sge          = 1;         
par.mem          = '16G';
par.jobname      = 'SEG_CAT12';

job_do_segmentCAT12(fanat,par)


% Check segmentation



%--------------------------------------------------------------------------
%                      Step 2
%                    Slicetiming 
%                    Using SPM
%                -------------------




dfunc = get_subdir_regex_multi(suj, 'IRMf');

clear par;

par.use_JSON        = 0;  % Here, we manually specify the order of the slices.       
par.reference_slice = 'middle';   % first / middle / last / sliceNumber (integer)
par.slice_order     = 'interleaved_ascending';



par.display  = 0; 
par.run      = 0;
par.sge      = 1;
par.jobname  = 'SliceTiming';

j = job_slice_timing(dfunc,par); 


% The resulting image starts with the prefix 'a'.
% Visualize and check the 4d image 

%--------------------------------------------------------------------------
%                     Step 3
%                     Realign 
%                    using SPM
%                  -------------



clear par
par.file_reg    = '^af.*nii';
par.type        = 'estimate_and_reslice';

par.display  = 0; 
par.run      = 0;
par.sge      = 1;
par.jobname  = 'REALIGN';

j = job_realign(dfunc,par);



% The resulting image starts with the prefix "ra".
% Visualize the 4d image and navigate between volumes using mrview.

% The txt file, prefixed with rp, contains the estimated parameters of the 
% spatial transformation (translations and rotations) of each volume with 
% respect to the reference volume.

rp = gfile(dfunc,'^rp.*txt');
plot_realign(rp(2))             % Plot 2nd subject




% -------------------------------------------------------------------------
%                           Step 3
%                       coregistration 
%                          using SPM
%                      ----------------

% Realign functional images with anatomical images.

mri    = get_subdir_regex_multi(danat, '^mri');
fbrain = get_subdir_regex_files(mri,'^p0.*nii',1);  

fmean  = get_subdir_regex_files(dfunc,'^mean.*nii');
fo     = gfile(dfunc,'^raf.*nii');



clear par
par.type     = 'estimate';

par.run      = 0;
par.sge      = 1;
par.jobname  = 'COREGISTER';
job_coregister(fmean,fanat,fo,par);


% /!\ Check the coregistration, using SPM checkreg or mrview 
% Use overlap option with mrview



% Compute a robust EPI mask

clear par
par.fsl_output_format = 'NIFTI';
par.run  = 0;
par.sge  = 1;
par.jobname  = 'EPI_MASK'
do_fsl_robust_mask_epi(fmean,par);

%--------------------------------------------------------------------------
%                         Step 4   
%                      Normalisation 
%                        usinig SPM
%                      --------------


% Normalizing the fMRI images to MNI template.


% Use the deformation matrix starting with 'y' (obtained during the 
% segmentation of the T1 image) to warp the functional images to a common
% space "MNI template".

fy     = gfile(mri,'^y');
fo     = gfile(dfunc,'^raf.*nii');


clear par
par.run  = 0;
par.sge  = 1;
par.jobname  = 'NORMALIZE';


j= job_apply_normalize(fy,fo,par)


% Check the overlap of the normalized images across subjects.



%--------------------------------------------------------------------------
%                     Step 5
%                     Smooth
%                    using SPM
%                  -------------


% Smoothing with a Gaussian

ffunc = gfile(dfunc,'^wraf.*nii')

clear par 
par.smooth = [6 6 6];

par.run  = 0;
par.sge  = 1;
par.walltime = '04:00:00';
par.jobname  = 'SMOOTH';

j = job_smooth(ffunc,par);



% Use the "batch_denoise_rsfMRI.m" script to perform data cleaning and filtering..
