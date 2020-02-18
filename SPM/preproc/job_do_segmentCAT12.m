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
    volumeArray  = img;
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
defpar.TPMC      = [0 0 1 0]; %                          (wp[456]*) /                        (mwp[456]*) /              (p[456]*) /                            (rp[456]*)

% dartel (rp0*)(rp[456]*)(rms*)      0 -> No
%                                    1 -> Rigid (SPM12 default)
%                                    2 -> Affine
%                                    3 -> Both
%
% Values can be :               0,1           / 0,1               / 0,1,2,3
defpar.label     = [0 0 0] ;  % native (p0*)  / normalize (wp0*)  / dartel (rp0*)      This will create a label map : p0 = (1 x p1) + (3 x p2) + (1 x p3)
defpar.bias      = [1 1 0] ;  % native (m*)   / normalize (wm*)   / dartel (rm*)       This will save the bias field corrected  + SANLM (global) T1
defpar.las       = [0 0 0] ;  % native (mi*)  / normalize (wmi*)  / dartel (rmi*)      This will save the bias field corrected  + SANLM (local)  T1

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

% Subdir ?
global cat; cat_defaults; cat.extopts.subfolders=par.subfolder;

% Check if expertgui is enabeled
assert(cat.extopts.expertgui==2,'cat.extopts.expertgui = 2 is mandatory. Check cat_defaults.m and reset SPM with spm_jobman(''initcfg'')')


%% Prepare job generation

% unzip volumes if required
if obj
    volumeArray.unzip(par);
    img = volumeArray.toJob;
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
    of = ap(img(nbsuj),'y_');
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
    
    % TPMC
    jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.warped = par.TPMC(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.mod    = par.TPMC(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.native = par.TPMC(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.dartel = par.TPMC(4);
    
    %----------------------------------------------------------------------
    
    % Bias field, using SANML for denoising
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.native = par.bias(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.warped = par.bias(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.dartel = par.bias(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.las .native = par. las(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.las .warped = par. las(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.las .dartel = par. las(3);
    
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
% Here, the order to add volumes looks weird, but its normal.
% This order is due to the behaviour of "tag", you have anticipate the overwrite of objects when they have similar tags
% For example, if you want to add p1 and wp1, add first p1 and then wp1, or else you will have overwrite

if obj && par.auto_add_obj && (par.run || par.sge)
    
    for iVol = 1 : length(volumeArray)
        
        % Shortcut
        vol = volumeArray(iVol);
        ser = vol.serie;
        tag = vol.tag;
        
        if par.run %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            ext = '.*.nii$';
            
            %--------------------------------------------------------------
            % bias field corrected  + SANLM (global) T1
            %--------------------------------------------------------------
            if par.bias(1), ser.addVolume([ '^m' tag ext],[ 'm' tag],1), end
            if par.bias(2), ser.addVolume(['^wm' tag ext],['wm' tag],1), end
            switch par.bias(3)
                case 0 % pass
                case 1, ser.addVolume(['^rm' tag '.*_rigid'  ext],['rm' tag '_rigid' ],1)
                case 2, ser.addVolume(['^rm' tag '.*_affine' ext],['rm' tag '_affine'],1)
                case 3, ser.addVolume(['^rm' tag '.*_affine' ext],['rm' tag '_affine'],1)
            end
            
            %--------------------------------------------------------------
            % bias field corrected  + SANLM (local)  T1
            %--------------------------------------------------------------
            if par.las(1), ser.addVolume([ '^mi' tag ext],[ 'mi' tag],1), end
            if par.las(2), ser.addVolume(['^wmi' tag ext],['wmi' tag],1), end
            switch par.las(3)
                case 0 % pass
                case 1, ser.addVolume(['^rmi' tag '.*_rigid'  ext],['rmi' tag '_rigid' ],1)
                case 2, ser.addVolume(['^rmi' tag '.*_affine' ext],['rmi' tag '_affine'],1)
                case 3, ser.addVolume(['^rmi' tag '.*_affine' ext],['rmi' tag '_affine'],1)
            end
            
            %--------------------------------------------------------------
            % label
            %--------------------------------------------------------------
            if par.label(1), ser.addVolume([ '^p0' tag ext],[ 'p0' tag],1), end
            if par.label(2), ser.addVolume(['^wp0' tag ext],['wp0' tag],1), end
            switch par.label(3)
                case 0 % pass
                case 1, ser.addVolume(['^rp0' tag '.*_rigid'  ext],['rp0' tag '_rigid' ],1)
                case 2, ser.addVolume(['^rp0' tag '.*_affine' ext],['rp0' tag '_affine'],1)
                case 3
                    ser.addVolume(['^rp0' tag '.*_rigid'  ext],['rp0' tag '_rigid' ],1)
                    ser.addVolume(['^rp0' tag '.*_affine' ext],['rp0' tag '_affine'],1)
            end
            
            %--------------------------------------------------------------
            % GM
            %--------------------------------------------------------------
            if par.GM(3), ser.addVolume([  '^p1' tag ext],[  'p1' tag],1), end
            switch par.GM(4)
                case 0 % pass
                case 1, ser.addVolume([ '^rp1' tag '.*_rigid'  ext],[ 'rp1' tag '_rigid' ],1)
                case 2, ser.addVolume([ '^rp1' tag '.*_affine' ext],[ 'rp1' tag '_affine'],1)
                case 3
                    ser.addVolume([ '^rp1' tag '.*_rigid'  ext],[ 'rp1' tag '_rigid' ],1)
                    ser.addVolume([ '^rp1' tag '.*_affine' ext],[ 'rp1' tag '_affine'],1)
            end
            if par.GM(1), ser.addVolume([ '^wp1' tag ext],[ 'wp1' tag],1), end
            switch par.GM(2)
                case 0 % pass
                case 1, ser.addVolume(['^mwp1'  tag ext],['mwp1'  tag],1)
                case 2, ser.addVolume(['^m0wp1' tag ext],['m0wp1' tag],1)
            end
            
            %--------------------------------------------------------------
            % WM
            %--------------------------------------------------------------
            if par.WM(3), ser.addVolume([  '^p2' tag ext],[  'p2' tag],1), end
            switch par.WM(4)
                case 0 % pass
                case 1, ser.addVolume([ '^rp2' tag '.*_rigid'  ext],[ 'rp2' tag '_rigid' ],1)
                case 2, ser.addVolume([ '^rp2' tag '.*_affine' ext],[ 'rp2' tag '_affine'],1)
                case 3
                    ser.addVolume([ '^rp2' tag '.*_rigid'  ext],[ 'rp2' tag '_rigid' ],1)
                    ser.addVolume([ '^rp2' tag '.*_affine' ext],[ 'rp2' tag '_affine'],1)
            end
            if par.WM(1), ser.addVolume([ '^wp2' tag ext],[ 'wp2' tag],1), end
            switch par.WM(2)
                case 0 % pass
                case 1, ser.addVolume(['^mwp2'  tag ext],['mwp2'  tag],1)
                case 2, ser.addVolume(['^m0wp2' tag ext],['m0wp2' tag],1)
            end
            
            %--------------------------------------------------------------
            % CSF
            %--------------------------------------------------------------
            if par.CSF(3), ser.addVolume([  '^p3' tag ext],[  'p3' tag],1), end
            switch par.CSF(4)
                case 0 % pass
                case 1, ser.addVolume([ '^rp3' tag '.*_rigid'  ext],[ 'rp3' tag '_rigid' ],1)
                case 2, ser.addVolume([ '^rp3' tag '.*_affine' ext],[ 'rp3' tag '_affine'],1)
                case 3
                    ser.addVolume([ '^rp3' tag '.*_rigid'  ext],[ 'rp3' tag '_rigid' ],1)
                    ser.addVolume([ '^rp3' tag '.*_affine' ext],[ 'rp3' tag '_affine'],1)
            end
            if par.CSF(1), ser.addVolume([ '^wp3' tag ext],[ 'wp3' tag],1), end
            switch par.CSF(2)
                case 0 % pass
                case 1, ser.addVolume(['^mwp3'  tag ext],['mwp3'  tag],1)
                case 2, ser.addVolume(['^m0wp3' tag ext],['m0wp3' tag],1)
            end
            
            %--------------------------------------------------------------
            % TPMC
            %--------------------------------------------------------------
            if par.TPMC(3)
                ser.addVolume([ '^p4' tag ext],[ 'p4' tag],1)
                ser.addVolume([ '^p5' tag ext],[ 'p5' tag],1)
                ser.addVolume([ '^p6' tag ext],[ 'p6' tag],1)
            end
            switch par.TPMC(4)
                case 0 % pass
                case 1
                    ser.addVolume([ '^rp4' tag '.*_rigid'  ext],[ 'rp4' tag '_rigid' ],1)
                    ser.addVolume([ '^rp5' tag '.*_rigid'  ext],[ 'rp5' tag '_rigid' ],1)
                    ser.addVolume([ '^rp6' tag '.*_rigid'  ext],[ 'rp6' tag '_rigid' ],1)
                case 2
                    ser.addVolume([ '^rp4' tag '.*_affine' ext],[ 'rp4' tag '_affine'],1)
                    ser.addVolume([ '^rp5' tag '.*_affine' ext],[ 'rp5' tag '_affine'],1)
                    ser.addVolume([ '^rp6' tag '.*_affine' ext],[ 'rp6' tag '_affine'],1)
                case 3
                    ser.addVolume([ '^rp4' tag '.*_rigid'  ext],[ 'rp4' tag '_rigid' ],1)
                    ser.addVolume([ '^rp5' tag '.*_rigid'  ext],[ 'rp5' tag '_rigid' ],1)
                    ser.addVolume([ '^rp6' tag '.*_rigid'  ext],[ 'rp6' tag '_rigid' ],1)
                    ser.addVolume([ '^rp4' tag '.*_affine' ext],[ 'rp4' tag '_affine'],1)
                    ser.addVolume([ '^rp5' tag '.*_affine' ext],[ 'rp5' tag '_affine'],1)
                    ser.addVolume([ '^rp6' tag '.*_affine' ext],[ 'rp6' tag '_affine'],1)
            end
            if par.TPMC(1)
                ser.addVolume([ '^wp4' tag ext],[ 'wp4' tag],1)
                ser.addVolume([ '^wp5' tag ext],[ 'wp5' tag],1)
                ser.addVolume([ '^wp6' tag ext],[ 'wp6' tag],1)
            end
            switch par.TPMC(2)
                case 0 % pass
                case 1
                    ser.addVolume(['^mwp4'  tag ext],['mwp4'  tag],1)
                    ser.addVolume(['^mwp5'  tag ext],['mwp5'  tag],1)
                    ser.addVolume(['^mwp6'  tag ext],['mwp6'  tag],1)
                case 2
                    ser.addVolume(['^m0wp4' tag ext],['m0wp4' tag],1)
                    ser.addVolume(['^m0wp5' tag ext],['m0wp5' tag],1)
                    ser.addVolume(['^m0wp6' tag ext],['m0wp6' tag],1)
            end
            
            %--------------------------------------------------------------
            % Jacobian
            %--------------------------------------------------------------
            if par.jacobian, ser.addVolume(['^wj_' tag ext],['wj_' tag],1), end
            
            %--------------------------------------------------------------
            % Warp field
            %--------------------------------------------------------------
            if par.warp(1), ser.addVolume([ '^y_' tag ext],[ 'y_' tag],1), end
            if par.warp(2), ser.addVolume(['^iy_' tag ext],['iy_' tag],1), end
            
            
        elseif par.sge %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %--------------------------------------------------------------
            % bias field corrected  + SANLM (global) T1
            %--------------------------------------------------------------
            if par.bias(1), ser.addVolume( 'root', ap(vol.path, 'm'),[ 'm' tag]), end
            if par.bias(2), ser.addVolume( 'root', ap(vol.path,'wm'),['wm' tag]), end
            switch par.bias(3)
                case 0 % pass
                case 1, ser.addVolume( 'root', as(ap(vol.path,'rm'),'_rigid' ),['rm' tag '_rigid' ])
                case 2, ser.addVolume( 'root', as(ap(vol.path,'rm'),'_affine'),['rm' tag '_affine'])
                case 3, ser.addVolume( 'root', as(ap(vol.path,'rm'),'_affine'),['rm' tag '_affine'])
            end
            
            %--------------------------------------------------------------
            % bias field corrected  + SANLM (local)  T1
            %--------------------------------------------------------------
            if par.las(1), ser.addVolume( 'root', ap(vol.path, 'mi'),[ 'mi' tag]), end
            if par.las(2), ser.addVolume( 'root', ap(vol.path,'wmi'),['wmi' tag]), end
            switch par.las(3)
                case 0 % pass
                case 1, ser.addVolume( 'root', as(ap(vol.path,'rmi'),'_rigid' ),['rmi' tag '_rigid' ])
                case 2, ser.addVolume( 'root', as(ap(vol.path,'rmi'),'_affine'),['rmi' tag '_affine'])
                case 3, ser.addVolume( 'root', as(ap(vol.path,'rmi'),'_affine'),['rmi' tag '_affine'])
            end
            
            %--------------------------------------------------------------
            % label
            %--------------------------------------------------------------
            if par.label(1), ser.addVolume( 'root', ap(vol.path, 'p0'),[ 'p0' tag]), end
            if par.label(2), ser.addVolume( 'root', ap(vol.path,'wp0'),['wp0' tag]), end
            switch par.label(3)
                case 0 % pass
                case 1, ser.addVolume( 'root', as(ap(vol.path,'rp0'),'_rigid' ),['rp0' tag '_rigid' ])
                case 2, ser.addVolume( 'root', as(ap(vol.path,'rp0'),'_affine'),['rp0' tag '_affine'])
                case 3
                    ser.addVolume( 'root', as(ap(vol.path,'rp0'),'_rigid' ),['rp0' tag '_rigid' ])
                    ser.addVolume( 'root', as(ap(vol.path,'rp0'),'_affine'),['rp0' tag '_affine'])
            end
            
            %--------------------------------------------------------------
            % GM
            %--------------------------------------------------------------
            if par.GM(3), ser.addVolume( 'root', ap(vol.path,'p1'),[  'p1' tag]), end
            switch par.GM(4)
                case 0 % pass
                case 1, ser.addVolume( 'root', as(ap(vol.path,'rp1'),'_rigid' ),[ 'rp1' tag '_rigid' ])
                case 2, ser.addVolume( 'root', as(ap(vol.path,'rp1'),'_affine'),[ 'rp1' tag '_affine'])
                case 3
                    ser.addVolume( 'root', as(ap(vol.path,'rp1'),'_rigid' ),[ 'rp1' tag '_rigid' ])
                    ser.addVolume( 'root', as(ap(vol.path,'rp1'),'_affine'),[ 'rp1' tag '_affine'])
            end
            if par.GM(1), ser.addVolume( 'root', ap(vol.path,'wp1'),[ 'wp1' tag]), end
            switch par.GM(2)
                case 0 % pass
                case 1, ser.addVolume( 'root', ap(vol.path,'mwp1' ),['mwp1'  tag])
                case 2, ser.addVolume( 'root', ap(vol.path,'m0wp1'),['m0wp1' tag])
            end
            
            %--------------------------------------------------------------
            % WM
            %--------------------------------------------------------------
            if par.WM(3), ser.addVolume( 'root', ap(vol.path,'p2'),[  'p2' tag]), end
            switch par.WM(4)
                case 0 % pass
                case 1, ser.addVolume( 'root', as(ap(vol.path,'rp2'),'_rigid' ),[ 'rp2' tag '_rigid' ])
                case 2, ser.addVolume( 'root', as(ap(vol.path,'rp2'),'_affine'),[ 'rp2' tag '_affine'])
                case 3
                    ser.addVolume( 'root', as(ap(vol.path,'rp2'),'_rigid' ),[ 'rp2' tag '_rigid' ])
                    ser.addVolume( 'root', as(ap(vol.path,'rp2'),'_affine'),[ 'rp2' tag '_affine'])
            end
            if par.WM(1), ser.addVolume( 'root', ap(vol.path,'wp2'),[ 'wp2' tag]), end
            switch par.WM(2)
                case 0 % pass
                case 1, ser.addVolume( 'root', ap(vol.path,'mwp2' ),['mwp2'  tag])
                case 2, ser.addVolume( 'root', ap(vol.path,'m0wp2'),['m0wp2' tag])
            end
            
            %--------------------------------------------------------------
            % CSF
            %--------------------------------------------------------------
            if par.CSF(3), ser.addVolume( 'root', ap(vol.path,'p3'),[  'p3' tag]), end
            switch par.CSF(4)
                case 0 % pass
                case 1, ser.addVolume( 'root', as(ap(vol.path,'rp3'),'_rigid' ),[ 'rp3' tag '_rigid' ])
                case 2, ser.addVolume( 'root', as(ap(vol.path,'rp3'),'_affine'),[ 'rp3' tag '_affine'])
                case 3
                    ser.addVolume( 'root', as(ap(vol.path,'rp3'),'_rigid' ),[ 'rp3' tag '_rigid' ])
                    ser.addVolume( 'root', as(ap(vol.path,'rp3'),'_affine'),[ 'rp3' tag '_affine'])
            end
            if par.CSF(1), ser.addVolume( 'root', ap(vol.path,'wp3'),[ 'wp3' tag]), end
            switch par.CSF(2)
                case 0 % pass
                case 1, ser.addVolume( 'root', ap(vol.path,'mwp3' ),['mwp3'  tag])
                case 2, ser.addVolume( 'root', ap(vol.path,'m0wp3'),['m0wp3' tag])
            end
            
            %--------------------------------------------------------------
            % TPMC
            %--------------------------------------------------------------
            if par.TPMC(3)
                ser.addVolume( 'root', ap(vol.path,'p4'),[ 'p4' tag])
                ser.addVolume( 'root', ap(vol.path,'p5'),[ 'p5' tag])
                ser.addVolume( 'root', ap(vol.path,'p6'),[ 'p6' tag])
            end
            switch par.TPMC(4)
                case 0 % pass
                case 1
                    ser.addVolume( 'root', as(ap(vol.path,'rp4'),'_rigid' ),[ 'rp4' tag '_rigid' ])
                    ser.addVolume( 'root', as(ap(vol.path,'rp5'),'_rigid' ),[ 'rp5' tag '_rigid' ])
                    ser.addVolume( 'root', as(ap(vol.path,'rp6'),'_rigid' ),[ 'rp6' tag '_rigid' ])
                case 2
                    ser.addVolume( 'root', as(ap(vol.path,'rp4'),'_affine'),[ 'rp4' tag '_affine'])
                    ser.addVolume( 'root', as(ap(vol.path,'rp5'),'_affine'),[ 'rp5' tag '_affine'])
                    ser.addVolume( 'root', as(ap(vol.path,'rp6'),'_affine'),[ 'rp6' tag '_affine'])
                case 3
                    ser.addVolume( 'root', as(ap(vol.path,'rp4'),'_rigid' ),[ 'rp4' tag '_rigid' ])
                    ser.addVolume( 'root', as(ap(vol.path,'rp5'),'_rigid' ),[ 'rp5' tag '_rigid' ])
                    ser.addVolume( 'root', as(ap(vol.path,'rp6'),'_rigid' ),[ 'rp6' tag '_rigid' ])
                    ser.addVolume( 'root', as(ap(vol.path,'rp4'),'_affine'),[ 'rp4' tag '_affine'])
                    ser.addVolume( 'root', as(ap(vol.path,'rp5'),'_affine'),[ 'rp5' tag '_affine'])
                    ser.addVolume( 'root', as(ap(vol.path,'rp6'),'_affine'),[ 'rp6' tag '_affine'])
            end
            if par.TPMC(1)
                ser.addVolume( 'root', ap(vol.path,'wp4'),[ 'wp4' tag])
                ser.addVolume( 'root', ap(vol.path,'wp5'),[ 'wp5' tag])
                ser.addVolume( 'root', ap(vol.path,'wp6'),[ 'wp6' tag])
            end
            switch par.TPMC(2)
                case 0 % pass
                case 1
                    ser.addVolume( 'root', ap(vol.path,'mwp4' ),['mwp4'  tag])
                    ser.addVolume( 'root', ap(vol.path,'mwp5' ),['mwp5'  tag])
                    ser.addVolume( 'root', ap(vol.path,'mwp6' ),['mwp6'  tag])
                case 2
                    ser.addVolume( 'root', ap(vol.path,'m0wp4'),['m0wp4' tag])
                    ser.addVolume( 'root', ap(vol.path,'m0wp5'),['m0wp5' tag])
                    ser.addVolume( 'root', ap(vol.path,'m0wp6'),['m0wp6' tag])
            end
            
            %--------------------------------------------------------------
            % Jacobian
            %--------------------------------------------------------------
            if par.jacobian, ser.addVolume( 'root', ap(vol.path,'wj_'),['wj_' tag]), end
            
            %--------------------------------------------------------------
            % Warp field
            %--------------------------------------------------------------
            if par.warp(1), ser.addVolume( 'root', ap(vol.path, 'y_'),[ 'y_' tag]), end
            if par.warp(2), ser.addVolume( 'root', ap(vol.path,'iy_'),['iy_' tag]), end
            
        end
        
    end % iVol
    
end % obj


end % function

% This is a like a shortcut, to reduce verbosity
function newlist = ap(filelist,prefix)
newlist = addprefixtofilenames(filelist,prefix);
end
function newlist = as(filelist,suffix)
newlist = addsuffixtofilenames(filelist,suffix);
end
