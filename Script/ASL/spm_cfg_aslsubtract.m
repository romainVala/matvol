function aslsubtract = spm_cfg_aslsubtract
% SPM Configuration file for 3D to 4D volumes conversion
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% John Ashburner
% $Id: spm_cfg_cat.m 3613 2009-12-04 18:47:59Z guillaume $

% Michèle Desjardins, January 2012


%--------------------------------------------------------------------------
% vols 3D Volumes
%--------------------------------------------------------------------------
vols         = cfg_files;
vols.tag     = 'vols';
vols.name    = '4D Volumes';
vols.help    = {'Select the ASL volumes.'};
vols.filter  = 'image';
vols.ufilter = '.*';
vols.num     = [2 Inf];

% -------------------------------------------------------------------------
% numSess Number of sessions (of identical length) included in vols
% -------------------------------------------------------------------------
numSess        = cfg_entry;
numSess.tag    = 'numSess';
numSess.name   = 'Number of sessions';
numSess.help   = {['Number of sessions (of identical length) included in the selected 4D volumes.' ...
    ' Each session will be treated independently (first session = first #vol/#sess, etc.).' ...
    ' This option can be useful when using dependencies in batch mode.']};
numSess.strtype = 'e';
numSess.num     = [1 1];
numSess.val{1}    = 1;

%--------------------------------------------------------------------------
% order File order
%--------------------------------------------------------------------------
order        = cfg_menu;
order.tag    = 'order';
order.name   = 'Order of volumes';
order.help   = {'Order in which volumes constituting the time series were selected.'};
order.labels = {'All control - then all tagged images'
                'All tagged - then all control images'
                'Control, tag, control, tag...'
                'Tag, control, tag, control...'}';
order.values = {1 2 3 4};
order.val    = {3}; % to match previous behaviour

% ---------------------------------------------------------------------
% doAddition Perform addition (instead of subtraction)
% ---------------------------------------------------------------------
doAddition        = cfg_menu;
doAddition.tag    = 'doAddition';
doAddition.name   = 'Addition/Subtraction';
doAddition.help   = {['Perform pairwise addition or subtraction of selected volumes of the time series.' ...
    ' Addition will yield BOLD contrast time series, subtraction flow contrast - provided the '...
    'sequence parameters were chosen accordingly.']};
doAddition.labels = {'Subtraction' 'Addition'};
doAddition.values = {0 1};
doAddition.val    = {0};

% ---------------------------------------------------------------------
% subMethod Subtraction method
% ---------------------------------------------------------------------
subMethod        = cfg_menu;
subMethod.tag    = 'subMethod';
subMethod.name   = 'Subtraction method';
subMethod.help   = {['Method for subtracting (adding) control/tag pairs.']};
subMethod.labels = {'Simple' 'Surround (NOT YET)' 'Sinc (NOT YET)'};
subMethod.values = {0 1 2};
subMethod.val    = {0};

% ---------------------------------------------------------------------
% mask Explicit mask
% ---------------------------------------------------------------------
mask         = cfg_files;
mask.tag     = 'mask';
mask.name    = 'Explicit mask';
mask.val{1} = {''};
mask.help    = {['Specify an image for explicitly masking the subtraction.'...
    'The image must be in the same space (dimensions, resoluion, registation) '...
    'as the ASL time series. It can be obtained from a segmentation of a '...
    'structural image that is then resliced to the space of the ASL volumes.'...
    'If omitted, an automatic mask will be created by thresholding the '...
    'ASL mean image.']};
mask.filter = 'image';
mask.ufilter = '.*';
mask.num     = [0 1];

% ---------------------------------------------------------------------
% fROI Region of interest
% ---------------------------------------------------------------------
fROI         = cfg_files;
fROI.tag     = 'fROI';
fROI.name    = 'Display ROI average';
fROI.val{1} = {''};
fROI.help    = {['Specify an image of an ROI in which to compute mean CBF.'...
                 ' If a ROI is specified, the average value of CBF over'... 
                 ' this ROI will be dissplayed in the command window. '...
                 ' The image should be in the same space as the ASL data.']};
fROI.filter = 'image';
fROI.ufilter = '.*';
fROI.num     = [0 1];


%--------------------------------------------------------------------------
% M0 Fully relaxed magnetization image
%--------------------------------------------------------------------------
M0         = cfg_files;
M0.tag     = 'M0';
M0.name    = 'M0 image';
M0.help    = {['Select the fully relaxed magnetization (M0) image. '...
    'It must be in spatial registration with the ASL time series. If '...
    'omitted, the mean control image will be used for flow calibration - ' ...
    'not recommanded for shorter TRs. This options is only relevant for ' ...
    'subtraction (flow contrast), not addition (BOLD contrast). ']};
M0.filter  = 'image';
M0.ufilter = '.*';
M0.num     = [0 1];
M0.val{1} = {''};

%--------------------------------------------------------------------------
% acqOrder Order of acquisitions of slices
%--------------------------------------------------------------------------
acqOrder        = cfg_menu;
acqOrder.tag    = 'acqOrder';
acqOrder.name   = 'Slices acquisition order';
acqOrder.help   = {'Order in which (z) slices were acquired.'};
acqOrder.labels = {'Ascending'
                'Descending'
                'Interleaved (?) - NOT YET'}';
acqOrder.values = {1 2 3};
acqOrder.val    = {1}; %

% ---------------------------------------------------------------------
% TE Echo time of ASL sequence
% ---------------------------------------------------------------------
TE         = cfg_entry;
TE.tag     = 'TE';
TE.name    = 'Echo time';
TE.help    = {'Echo time of the ASL sequence (in miliseconds).'};
TE.strtype = 'e';
TE.num     = [1 1];

% ---------------------------------------------------------------------
% TR Repetition time of ASL sequence
% ---------------------------------------------------------------------
TR         = cfg_entry;
TR.tag     = 'TR';
TR.name    = 'Repetition time';
TR.help    = {'Repetition time of the ASL sequence (in seconds).' ...
    'It is only used to estimate the acquisition time of 1 slice,' ...
    ' in order to correct acquisition time for each slice according to acquisiton order.'};
TR.strtype = 'e';
TR.num     = [1 1];


% ---------------------------------------------------------------------
% TI1 TI1 of PASL sequence
% ---------------------------------------------------------------------
TI1         = cfg_entry;
TI1.tag     = 'TI1';
TI1.name    = 'TI1';
TI1.help    = {'TI1 (in miliseconds).'};
TI1.strtype = 'e';
TI1.val{1}  = 700;
TI1.num     = [1 1];

% ---------------------------------------------------------------------
% TI2 TI2 of PASL sequence
% ---------------------------------------------------------------------
TI2         = cfg_entry;
TI2.tag     = 'TI2';
TI2.name    = 'TI2';
TI2.help    = {'TI2 (in miliseconds).'};
TI2.strtype = 'e';
TI2.val{1}  = 1400;
TI2.num     = [1 1];

% ---------------------------------------------------------------------
% postTagDelay Post-labelling delay of (p)CASL sequence
% ---------------------------------------------------------------------
postTagDelay         = cfg_entry;
postTagDelay.tag     = 'postTagDelay';
postTagDelay.name    = 'Post-labelling delay';
postTagDelay.help    = {'Post-labelling delay (in seconds).'};
postTagDelay.strtype = 'e';
postTagDelay.val{1}  = 0.9;
postTagDelay.num     = [1 1];

% ---------------------------------------------------------------------
% tagDur Labelling pulse duration of p(CASL) sequence
% ---------------------------------------------------------------------
tagDur         = cfg_entry;
tagDur.tag     = 'tagDur';
tagDur.name    = 'Labelling pulse duration';
tagDur.help    = {'Labelling pulse duration (in seconds).'};
tagDur.strtype = 'e';
tagDur.val{1}  = 1.5;
tagDur.num     = [1 1];

% ---------------------------------------------------------------------
% WMmask White matter mask
% ---------------------------------------------------------------------
WMmask         = cfg_files;
WMmask.tag     = 'WMmask';
WMmask.name    = 'White matter mask';
WMmask.help    = {['Mask image for white matter (used to compute white '...
    ' matter M0 value for CBF calibration. '...
    'The image must be in the same space (dimensions, resoluion, registation) '...
    'as the ASL time series. It can be obtained from a segmentation of a '...
    'structural image that is then resliced to the space of the ASL volumes.']};
WMmask.filter = 'image';
WMmask.ufilter = '.*';
WMmask.num     = [1 1];

% ---------------------------------------------------------------------
% CSFmask CSF mask
% ---------------------------------------------------------------------
CSFmask         = cfg_files;
CSFmask.tag     = 'CSFmask';
CSFmask.name    = 'CSF mask';
CSFmask.help    = {['Mask image for CSF (used to compute water '...
    ' M0 value for CBF calibration. '...
    'The image must be in the same space (dimensions, resoluion, registation) '...
    'as the ASL time series. It can be obtained from a segmentation of a '...
    'structural image that is then resliced to the space of the ASL volumes.']};
CSFmask.filter = 'image';
CSFmask.ufilter = '.*';
CSFmask.num     = [1 1];

% -------------------------------------------------------------------------
% useM0mean Use brain mean for M0 value (instead of individual voxel value)
% -------------------------------------------------------------------------
useM0mean        = cfg_menu;
useM0mean.tag    = 'useM0mean';
useM0mean.name   = 'Use mean M0';
useM0mean.help   = {['Use individual voxel value or brain mean value for ' ...
    'M0 in the computation of absolute flow calibration.']};
useM0mean.labels = {'Individual voxel value' 'Brain mean'};
useM0mean.values = {0 1};
useM0mean.val    = {1};

% ---------------------------------------------------------------------
% noCalibr (For skipping flow calibration)
% ---------------------------------------------------------------------
noCalibr         = cfg_branch;
noCalibr.tag     = 'noCalibr';
noCalibr.name    = 'No calibration';
noCalibr.val     = {};
noCalibr.help    = {'Absolute (quantitative) CBF will not be computed.'};

% ---------------------------------------------------------------------
% PASL Pulsed ASL sequence type
% ---------------------------------------------------------------------
PASL         = cfg_branch;
PASL.tag     = 'PASL';
PASL.name    = 'Pulsed ASL';
PASL.val     = {M0 WMmask TE TI1 TI2};
PASL.help    = {'For QUIPSS II (Q2TIPS) pulsed ASL (PASL) ; Buxton et al. MRM 40:383-396 (1998).'};

% ---------------------------------------------------------------------
% Wang Wang model (for (Pseudo-)Continuous ASL sequence type)
% ---------------------------------------------------------------------
Wang         = cfg_branch;
Wang.tag     = 'Wang';
Wang.name    = 'Wang';
Wang.val     = {M0 useM0mean postTagDelay acqOrder tagDur TR};
Wang.help    = {'For CASL or pCASL ; Wang 2003, MRM 50:600, Eq. 1.'};

% ---------------------------------------------------------------------
% vanOsch van Osch model (for (Pseudo-)Continuous ASL sequence type)
% ---------------------------------------------------------------------
vanOsch         = cfg_branch;
vanOsch.tag     = 'vanOsch';
vanOsch.name    = 'van Osch';
vanOsch.val     = {M0 CSFmask postTagDelay acqOrder TE TR tagDur};
vanOsch.help    = {'For CASL or pCASL ; van Osch et al. 2009, MRM 62:165-173 Eq. 1.'};

% ---------------------------------------------------------------------
% CBFmodel ASL sequence type
% ---------------------------------------------------------------------
CBFmodel         = cfg_choice;
CBFmodel.tag     = 'CBFmodel';
CBFmodel.name    = 'CBF calibration model';
CBFmodel.val     = {Wang };
CBFmodel.help    = {['Type of ASL sequence (pulsed or ' ...
    'continuous/pseudo-continuous). Used for flow calibration. ' ...
    'WARNING : Some literature values are hard-coded and some sequence' ...
    ' parameters are specific to particular implementations of the ' ...
    'sequence. This code could be generalized but was ' ...
    'written for data acquired at the CRIUGM (Jan. 2012).']};
CBFmodel.values  = {PASL Wang vanOsch noCalibr};

%--------------------------------------------------------------------------
% dtype Data Type
%--------------------------------------------------------------------------
dtype        = cfg_menu;
dtype.tag    = 'dtype';
dtype.name   = 'Data Type';
dtype.help   = {'Data-type of output image. SAME indicates the same datatype as the original images.'};
dtype.labels = {'SAME'
                'UINT8   - unsigned char'
                'INT16   - signed short'
                'INT32   - signed int'
                'FLOAT32 - single prec. float'
                'FLOAT64 - double prec. float'}';
dtype.values = {0 spm_type('uint8') spm_type('int16') spm_type('int32') spm_type('float32') spm_type('float64')};
dtype.val    = {spm_type('float32')}; % to match previous behaviour

%--------------------------------------------------------------------------
% name Output Filename
%--------------------------------------------------------------------------
name         = cfg_entry;
name.tag     = 'name';
name.name    = 'Output Filename';
name.help    = {'Specify the name of the output 4D volume file.'
                'A ''.nii'' extension will be added if not specified.'}';
name.strtype = 's';
name.num     = [1 Inf];
name.val     = {'flow4D.nii'};

% -------------------------------------------------------------------------
% save3D Save subtraction (addition) results in 3D files in addition to 4D
% -------------------------------------------------------------------------
save3D        = cfg_menu;
save3D.tag    = 'save3D';
save3D.name   = 'Save 3D output files';
save3D.help   = {['Also save output as 3D in addition to 4D.']};
save3D.labels = {'No (4D output only)' 'Yes (3D & 4D outputs)'};
save3D.values = {0 1};
save3D.val    = {0};

% -------------------------------------------------------------------------
% dont_recompute Boolean to skip recomputation of subtraction/addition and
% perform only calibration
% -------------------------------------------------------------------------
dont_recompute        = cfg_menu;
dont_recompute.tag    = 'dont_recompute';
dont_recompute.name   = 'Skip recomputation';
dont_recompute.help   = {['An option to skip computation of pairwise subtraction/addition' ...
    ' and perform only calibration (for flow), in case it has alreadey been computed.' ]};
dont_recompute.labels = {'No, do compute' 'Skip subtraction (calibration only)'};
dont_recompute.values = {0 1};
dont_recompute.val    = {0};

% -------------------------------------------------------------------------
% rmv_start_imgs Number of images to ignore in flow computation (useful
% when using dependencies in batch mode)
% -------------------------------------------------------------------------
rmv_start_imgs        = cfg_entry;
rmv_start_imgs.tag    = 'rmv_start_imgs';
rmv_start_imgs.name   = 'Ignore first X images';
rmv_start_imgs.help   = {['An option to ignore a number of images in the subtraction/addition.' ...
    ' Can be useful when using dependencies in batch mode (e.g., for excluding the mean image from'...
    ' the computation on the time series). Enter the number of images to ignore, from the 1st.']};
rmv_start_imgs.strtype = 'e';
rmv_start_imgs.num     = [1 1];
rmv_start_imgs.val{1}    = 0;


%--------------------------------------------------------------------------
% aslsubtract - Pairwise subtraction/addition of ASL time series
%--------------------------------------------------------------------------
aslsubtract         = cfg_exbranch;
aslsubtract.tag     = 'aslsubtract';
aslsubtract.name    = 'ASL subtraction/addition';
aslsubtract.val     = {vols numSess order CBFmodel doAddition subMethod...
    mask fROI name dtype save3D dont_recompute rmv_start_imgs};
aslsubtract.help    = {'Pairwise subtract (add) ASL time series to generate flow (BOLD) images.'};
aslsubtract.prog = @spm_run_aslsubtract;
aslsubtract.vout = @vout;

%==========================================================================
function dep = vout(varargin)
% 4D output file will be saved in a struct with field .flowfile
dep(1)            = cfg_dep;
dep(1).sname      = 'Subtraction/addition resulting 4D Volume';
dep(1).src_output = substruct('.','flowfile');
dep(1).tgt_spec   = cfg_findspec({{'filter','image','strtype','e'}});
dep(2)            = cfg_dep;
dep(2).sname      = 'Calibrated flow 4D Volume';
dep(2).src_output = substruct('.','calibflowfile');
dep(2).tgt_spec   = cfg_findspec({{'filter','image','strtype','e'}});
