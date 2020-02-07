function jobs = job_do_segmentCAT12(img,par)
% JOB_DO_SEGMENTCAT12
%
% SYNTAX
% JOB_DO_SEGMENTCAT12(img,par)
%
% INPUT
% - img : can be 'char' of volume(file), single-level 'cellstr' of volume(file), '@volume' array
% - par : classic matvol parameter structure
%
% IMPORTANT NOTE
% Check the "defpar" section below for tuning your job
%
%
% See also get_subdir_regex get_subdir_regex_files exam exam.addSerie exam.addVolume

if nargin==0, help(mfilename), return, end


%% Check CAT12 toolbox install

assert( ~isempty(which('cat12')), 'cat12.m not found you must install the toolbox')


%% Check input arguments

if ~exist('par', 'var')
    par='';
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - image list is required',mfilename)
end

obj = 0;
if isa(img,'volume')
    obj = 1;
    in_obj  = img;
elseif ischar(img) || iscellstr(img)
    % Ensure the inputs are cellstrings, to avoid dimensions problems
    img = cellstr(img)';
else
    error('[%s]: wrong input format (cellstr, char, @volume)', mfilename)
end


%% defpar

%- cat12 segmentation options ---------------------------------------------

defpar.subfolder = 0;         % 0 means "do not write in subfolder"

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

% warped_space_modulated    (mwp**)  0 -> No
%                                    1 -> Affine + non-linear (SPM12 default)
%                                    2 -> Non-Linear only
%
% native_space_dartel_import (rp**)  0 -> No
%                                    1 -> Rigid (SPM12 default)
%                                    2 -> Affine
%                                    3 -> Both
%
% Values can be :               0,1                                 / 0,1,2                              / 0,1                    / 0,1,2,3
defpar.GM        = [0 0 1 0]; % warped_space_Unmodulated (wp1*)     / warped_space_modulated (mwp1*)     / native_space (p1*)     / native_space_dartel_import (rp1*)
defpar.WM        = [0 0 1 0]; %                          (wp2*)     /                        (mwp2*)     /              (p2*)     /                            (rp2*)
defpar.CSF       = [0 0 1 0]; %                          (wp3*)     /                        (mwp3*)     /              (p3*)     /                            (rp3*)
defpar.TPMC      = [0 0 1 0]; %                          (wp[456]*) /                        (mwp[456]*) /              (p[456]*) /                            (rp[456]*)   This will create other probalities map (p4 p5 p6)

% dartel (rp0*)(rp[456]*)(rms*)      0 -> No
%                                    1 -> Rigid (SPM12 default)
%                                    2 -> Affine
%                                    3 -> Both
%
% Values can be :               0,1              / 0,1              / 0,1,2,3
defpar.label     = [0 0 0] ;  % native (p0*)     / normalize (wp0*) / dartel (rp0*)       This will create a label map : p0 = (1 x p1) + (3 x p2) + (1 x p3)
defpar.bias      = [1 1 0] ;  % native (ms*)     / normalize (wms*) / dartel (rms*)       This will save the bias field corrected  + SANLM T1

defpar.warp      = [1 1];     % Warp fields  : native->template (y_*) / native<-template (iy_*)

% Surface
% 0  -> No
% 1  -> lh + rh
% 2  -> lh + rh + cerebellum
% 5  -> lh + rh (fast, no registration)
% 6  -> lh + rh + cerebellum (fast, no registration)
% 7  -> lh + rh (fast registration)
% 8  -> lh + rh + cerebellum (fast registration)
% 9  -> Thickness estimation (for ROI analysis only)
% 12 -> Full
defpar.doSurface = 0;

% Atlas
% - neuromorphics
% - ipba40
% - cobra
% - hammers
% - ibsr
% - aal
% - mori
% - anatomy
defpar.doROI     = 0;         % Will compute the volume in each atlas region

defpar.jacobian  = 1;         % Write jacobian determinant in normalize space


%--------------------------------------------------------------------------

% matvol classics
defpar.run          = 1;
defpar.display      = 0;
defpar.redo         = 0;
defpar.sge          = 0;
defpar.auto_add_obj = 1;

% cluster
defpar.jobname  = 'spm_segmentCAT12';
defpar.walltime = '04:00:00';

par = complet_struct(par,defpar);

% subfolder trick : the line bellow will be executed before the spm_jobman(), especially useful for cluster
defpar.cmd_prepend = sprintf('global cat; cat_defaults; cat.extopts.subfolders=%d;',par.subfolder);
defpar.matlab_opt  = ' -nodesktop ';

par = complet_struct(par,defpar);

global cat; cat_defaults; cat.extopts.subfolders=par.subfolder;


%% Prepare job generation

% unzip volumes if required
if obj
    in_obj.unzip(par);
    img = in_obj.toJob;
else
    if ~iscell(img)
        img = cellstr(img);
    end
    img = unzip_volume(img);
end


%% Prepare job

skip=[];

for nbsuj = 1:length(img)
    
    % skip if y_ exist
    of = addprefixtofilenames(img(nbsuj),'y_');
    if ~par.redo  &&  exist(of{1},'file')
        skip = [skip nbsuj];
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,nbsuj,of{1});
    end
    
    jobs{nbsuj}.spm.tools.cat.estwrite.data = cellstr(img{nbsuj}); %#ok<*AGROW>
    jobs{nbsuj}.spm.tools.cat.estwrite.nproc = 0;
    
    jobs{nbsuj}.spm.tools.cat.estwrite.opts.bias.biasstr = par.biasstr;
    jobs{nbsuj}.spm.tools.cat.estwrite.opts.acc.accstr   = par.accstr;
    
    % ROI
    if par.doROI
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.atlases.neuromorphometrics = 1;
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.atlases.lpba40             = 1;
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.atlases.cobra              = 1;
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.atlases.hammers            = 1;
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.atlases.ibsr               = 1;
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.atlases.aal                = 1;
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.atlases.mori               = 1;
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.atlases.anatomy            = 1;
    else
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.noROI = struct([]);
    end %else take the default
    
    % Surface
    jobs{nbsuj}.spm.tools.cat.estwrite.output.surface = par.doSurface;
    
    %----------------------------------------------------------------------
    %- Tissue Probability Maps (TMP)
    
    % GM
    jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.warped = par.GM(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.mod    = par.GM(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.native = par.GM(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.dartel = par.GM(4);
    
    % WM
    jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.warped = par.WM(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.mod    = par.WM(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.native = par.WM(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.dartel = par.WM(4);
    
    % CSF
    jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.warped = par.CSF(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.mod    = par.CSF(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.native = par.CSF(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.dartel = par.CSF(4);
    
    % TMPC
    jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.native = par.TPMC(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.mod    = par.TPMC(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.warped = par.TPMC(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.dartel = par.TPMC(4);
    
    %----------------------------------------------------------------------
    
    % Bias field, using SANML for denoising
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.native = par.bias(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.warped = par.bias(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.dartel = par.bias(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.las .native = par.bias(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.las .warped = par.bias(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.las .dartel = par.bias(3);
    
    % Labels
    jobs{nbsuj}.spm.tools.cat.estwrite.output.label.native = par.label(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.label.warped = par.label(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.label.dartel = par.label(3);
    
    % Jacobian
    jobs{nbsuj}.spm.tools.cat.estwrite.output.jacobianwarped = par.jacobian;
    
    % Warp fields : y_ & iy_
    jobs{nbsuj}.spm.tools.cat.estwrite.output.warps = par.warp;
    
end % for : nsubj


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


%% Add outputs objects

if obj && par.auto_add_obj && par.run
    
    serieArray = [in_obj.serie];
    tag        =  in_obj(1).tag;
    ext        = '.*.nii$';
    
    % Warp field
    if par.warp(2), serieArray.addVolume([ '^y_' tag ext],[ 'y_' tag],1), end % Forward
    if par.warp(1), serieArray.addVolume(['^iy_' tag ext],['iy_' tag],1), end % Inverse
    
    % Bias field
    if par.bias(1), serieArray.addVolume([ '^m' tag ext],[ 'm' tag],1), end % Corrected
    if par.bias(2), serieArray.addVolume(['^wm' tag ext],['wm' tag],1), end % Field
    
    % GM
    if par.GM (3), serieArray.addVolume([  '^p1' tag ext],[  'p1' tag]), end % native_space(p*)
    if par.GM (4), serieArray.addVolume([ '^rp1' tag ext],[ 'rp1' tag]), end % native_space_dartel_import(rp*)
    if par.GM (1), serieArray.addVolume([ '^wp1' tag ext],[ 'wp1' tag]), end % warped_space_Unmodulated(wp*)
    if par.GM (2), serieArray.addVolume(['^mwp1' tag ext],['mwp1' tag]), end % warped_space_modulated(mwp*)
    
    % WM
    if par.WM (3), serieArray.addVolume([  '^p2' tag ext],[  'p2' tag]), end % native_space(p*)
    if par.WM (4), serieArray.addVolume([ '^rp2' tag ext],[ 'rp2' tag]), end % native_space_dartel_import(rp*)
    if par.WM (1), serieArray.addVolume([ '^wp2' tag ext],[ 'wp2' tag]), end % warped_space_Unmodulated(wp*)
    if par.WM (2), serieArray.addVolume(['^mwp2' tag ext],['mwp2' tag]), end % warped_space_modulated(mwp*)
    
    % CSF
    if par.CSF(3), serieArray.addVolume([  '^p3' tag ext],[  'p3' tag]), end % native_space(p*)
    if par.CSF(4), serieArray.addVolume([ '^rp3' tag ext],[ 'rp3' tag]), end % native_space_dartel_import(rp*)
    if par.CSF(1), serieArray.addVolume([ '^wp3' tag ext],[ 'wp3' tag]), end % warped_space_Unmodulated(wp*)
    if par.CSF(2), serieArray.addVolume(['^mwp3' tag ext],['mwp3' tag]), end % warped_space_modulated(mwp*)
    
end


end % function
