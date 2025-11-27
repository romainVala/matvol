
function jobs = job_seg_longitudinal_data(fanat, par)
% JOB_SEG_LONGITUDINAL  : Cat12, Segment Longitudinal
%
% Inputs:
%         fanat : cellstr of T1 files paths acquired in different time
%               point for each subject. use for example "get_subdir_regex_files" function
%               to select more then one file
%         par   : matvol & cat12 parameters 
%
% Note than, if the numbre of files is diffrent between the subjects, we
% chose the subject mode to specify longitudinal data and not time point
%
% For more information see :
%         https://neuro-jena.github.io/cat12-help/#long_process
%--------------------------------------------------------------------------

if ~exist('par','var'), par=''; end

% default parametres
%  longitudinal_data : say that is a parameter to choose the mode of
%
% Longitudinal Model
% 1: Optimized for detecting small changes, i.e. plasticity/learning effects
% 2: Optimized for detecting large changes, i.e. aging/developmental effects
% 3: both longitudinal models
defpar.longmodel = 2;      % choose : 1, 2 or 3 


% Strength of the SPM inhomogeneity (bias) correction that simultaneously controls the SPM biasreg and biasfwhm parameter.
% Modify this value only if you experience any problems!
% Use smaller values (>0) for slighter corrections (e.g. in synthetic contrasts without visible bias) and higher values (<=1) for stronger corrections (e.g. in 7 Tesla data).
% Bias correction is further controlled by the Affine Preprocessing (APP).
%  eps -> ultralight
% 0.25 -> light
% 0.50 -> medium (CAT12 default)
% 0.75 -> strong
% 1.00 -> heavy
defpar.biasstr   = 0.5;

% Parameter to control the accuracy of SPM preprocessing functions. In most images the standard accuracy is good enough for the initialization in CAT.
% However, some images with servere (local) inhomogeneities or atypical anatomy may benefit by additional iterations and higher resolution.
%  eps -> ltra low  (superfast)
% 0.25 -> low       (fast)
% 0.50 -> average   (default)
% 0.75 -> high      (slow)
% 1.00 -> ulta high (very slow)
defpar.accstr    = 0.5;


% Surface and thichness estimation 
defpar.surface = 0;    % 0: No, 1: Yes 


% Modulated GM/WM segmentations
defpar.modulate = 1;   % 0: No, 1: Yes

% DARTEL export
defpar.dartel   = 0;   % 0: No, 1: Yes

% Use longitudinal TPM from average image.
defpar.longTPM  = 1;   % 0: No, 1: Yes


defpar.nproc    = 4;

% classic matvol
defpar.run          = 1;
defpar.redo         = 0;    
defpar.auto_add_obj = 1;

% cluster
defpar.sge      = 0;
defpar.mem      = '8G';
defpar.walltime = '12';
defpar.jobname  = 'cat12LongSagment';


par = complet_struct(par,defpar);

% Specify the mode
[nbr_time_point, ~]  = cellfun(@size,fanat);           % number of time points for each subject
nbr_varying_num      = length(unique(nbr_time_point)); % numbre of varying number of time points




for nbr = 1:length(fanat)
    
    % skip subj avec par.redo = 0
    
    
    if nbr_varying_num == 1 && length(fanat) ~= 1
        
        %       Not yet
        %    use time point
      
    else
        % Varying number of time points for each subject
        % Using  "subjects" mode
        jobs{nbr}.spm.tools.cat.long.datalong.subjects =  {cellstr(fanat{nbr})} ;
              
    end
    
    
    jobs{nbr}.spm.tools.cat.long.longmodel    = par.longmodel;    % par.longmodel
    jobs{nbr}.spm.tools.cat.long.enablepriors = 1;                % par.enablepriors
    jobs{nbr}.spm.tools.cat.long.bstr         = 0;                % bias strength 
    jobs{nbr}.spm.tools.cat.long.nproc        = par.nproc;        % nbr processeur  !?
    
    
    
    jobs{nbr}.spm.tools.cat.long.opts.tpm          = {'/network/iss/cenir/software/irm/spm12/tpm/TPM.nii'};
    jobs{nbr}.spm.tools.cat.long.opts.affreg       = 'mni';        % Affine Regularisation
    jobs{nbr}.spm.tools.cat.long.opts.ngaus        = [1 1 2 3 4 2];
    jobs{nbr}.spm.tools.cat.long.opts.warpreg      = [0 0.001 0.5 0.05 0.2];
    jobs{nbr}.spm.tools.cat.long.opts.bias.biasstr = par.biasstr   % 0.5;
    jobs{nbr}.spm.tools.cat.long.opts.acc.accstr   = par.accstr;   % average
    jobs{nbr}.spm.tools.cat.long.opts.redspmres    = 0;            % SPM preprocessing output resolution limit
    
    
    
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.restypes.optimal     = [1 0.3];
%   matlabbatch{1}.spm.tools.cat.long.extopts.segmentation.restypes.native = struct([]); 
%   matlabbatch{1}.spm.tools.cat.long.extopts.segmentation.restypes.best   = [1 0.3];
%   matlabbatch{1}.spm.tools.cat.long.extopts.segmentation.restypes.fixed  = [1 0.1];

    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.setCOM     = 1;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.APP        = 1070;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.affmod     = 0;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.NCstr      = -Inf;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.spm_kamap  = 0;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.LASstr     = 0.5;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.LASmyostr  = 0;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.gcutstr    = 2;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.cleanupstr = 0.5;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.BVCstr = 0.5;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.WMHC   = 2;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.SLC    = 0;
    jobs{nbr}.spm.tools.cat.long.extopts.segmentation.mrf    = 1;
    
    
    jobs{nbr}.spm.tools.cat.long.extopts.registration.T1 = {'/network/iss/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/T1.nii'};
    jobs{nbr}.spm.tools.cat.long.extopts.registration.brainmask   = {'/network/iss/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/brainmask.nii'};
    jobs{nbr}.spm.tools.cat.long.extopts.registration.cat12atlas  = {'/network/iss/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/cat.nii'};
    jobs{nbr}.spm.tools.cat.long.extopts.registration.darteltpm   = {'/network/iss/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/Template_1_Dartel.nii'};
    jobs{nbr}.spm.tools.cat.long.extopts.registration.shootingtpm = {'/network/iss/cenir/software/irm/spm12/toolbox/cat12/templates_MNI152NLin2009cAsym/Template_0_GS.nii'};
    jobs{nbr}.spm.tools.cat.long.extopts.registration.regstr = 0.5;
    jobs{nbr}.spm.tools.cat.long.extopts.registration.bb  = 12;
    jobs{nbr}.spm.tools.cat.long.extopts.registration.vox = 1.5;
    
    
    jobs{nbr}.spm.tools.cat.long.extopts.surface.pbtres = 0.5;
    jobs{nbr}.spm.tools.cat.long.extopts.surface.pbtmethod = 'pbt2x';
    jobs{nbr}.spm.tools.cat.long.extopts.surface.SRP = 22;
    jobs{nbr}.spm.tools.cat.long.extopts.surface.reduce_mesh = 1;
    jobs{nbr}.spm.tools.cat.long.extopts.surface.vdist = 2;
    jobs{nbr}.spm.tools.cat.long.extopts.surface.scale_cortex   = 0.7;
    jobs{nbr}.spm.tools.cat.long.extopts.surface.add_parahipp   = 0.1;
    jobs{nbr}.spm.tools.cat.long.extopts.surface.close_parahipp = 1;
    
    jobs{nbr}.spm.tools.cat.long.extopts.admin.experimental = 0;
    jobs{nbr}.spm.tools.cat.long.extopts.admin.new_release  = 0;
    jobs{nbr}.spm.tools.cat.long.extopts.admin.lazy = 0;
    jobs{nbr}.spm.tools.cat.long.extopts.admin.ignoreErrors = 1;
    jobs{nbr}.spm.tools.cat.long.extopts.admin.verb  = 2;
    jobs{nbr}.spm.tools.cat.long.extopts.admin.print = 2;
    jobs{nbr}.spm.tools.cat.long.output.BIDS.BIDSno = 1;
    jobs{nbr}.spm.tools.cat.long.output.surface     = par.surface;
    
    % doROI 
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.neuromorphometrics = 1;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.lpba40             = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.cobra              = 1;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.hammers            = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.thalamus           = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.ibsr               = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.aal3               = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.mori               = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.anatomy3           = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.julichbrain        = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.Schaefer2018_100Parcels_17Networks_order = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.Schaefer2018_200Parcels_17Networks_order = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.Schaefer2018_400Parcels_17Networks_order = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.Schaefer2018_600Parcels_17Networks_order = 0;
    jobs{nbr}.spm.tools.cat.long.ROImenu.atlases.ownatlas = {''};
    
    jobs{nbr}.spm.tools.cat.long.longTPM     = par.longTPM;
    jobs{nbr}.spm.tools.cat.long.modulate    = par.modulate;
    jobs{nbr}.spm.tools.cat.long.dartel      = par.dartel;
    jobs{nbr}.spm.tools.cat.long.delete_temp = 1;
    
    
end


[ jobs ] = job_ending_rountines( jobs, [], par );
% spm_jobman('run', jobs,inputs)
end
