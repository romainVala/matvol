function  jobs = job_do_segmentCAT12(img,par)
%
% INPUT : img can be 'char' of volume(file), single-level 'cellstr' of volume(file), '@volume' array
%
% for spm12 segment, if img{1} has several line then it is a multichannel
%
% 'par' allow you to specify which output to save  defaults are
%   par.GM   = [0 0 1 0]; % warped_space_Unmodulated(wp*) / warped_space_modulated(mwp*) / native_space(p*) / native_space_dartel_import(rp*)
%   par.WM   = [0 0 1 0];
%   par.CSF  = [0 0 1 0];
%   par.bias = [0 1]; % bias field / bias corrected image
%   par.warp = [1 1]; % warp field native->template / warp field native<-template
%
% See also get_subdir_regex get_subdir_regex_files exam exam.AddSerie exam.addVolume


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

% Retrocompatibility for SPM:Spatial:Segment options
defpar.GM        = [0 0 1 0]; % warped_space_Unmodulated(wp*) / warped_space_modulated(mwp*) / native_space(p*) / native_space_dartel_import(rp*)
defpar.WM        = [0 0 1 0];
defpar.CSF       = [0 0 1 0];
defpar.bias      = [1 1 0] ;  % native normalize dartel     [0 1]; % bias field / bias corrected image
defpar.label       = [0 0 0] ;  % native normalize dartel
defpar.TPMC       = [0 0 0] ;  % native normalize dartel  to write other  Tissu Probability Map Classes 
defpar.warp      = [1 1]; % warp field native->template / warp field native<-template

defpar.jacobian  = 1;         % write jacobian determinant in normalize space
defpar.doROI     = 1;
defpar.doSurface = 1;
defpar.subfolder = 0; % all results in the same subfolder

defpar.auto_add_obj = 1;

defpar.run     = 0;
defpar.display = 0;
defpar.redo    = 0;
defpar.sge     = 0;

defpar.jobname  = 'spm_segmentCAT';
defpar.walltime = '02:00:00';

par = complet_struct(par,defpar);

if any(par.TPMC),    expert_mode=2; else expert_mode=1; end
defpar.cmd_prepend = sprintf('global cat; cat_defaults; cat.extopts.subfolders=%d; cat.extopts.expertgui=%d;clear defaults; spm_jobman(''initcfg'');',...
    par.subfolder,expert_mode);
defpar.matlab_opt = ' -nodesktop ';


par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end


%% Prepare job generation

%to make expert mode active if not done
global cat;cat_defaults;
if cat.extopts.expertgui==0
    eval(par.cmd_prepend)
end

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
    
    %spm_dir=spm('Dir'); %fileparts(which ('spm'));
    jobs{nbsuj}.spm.tools.cat.estwrite.data = cellstr(img{nbsuj}); %#ok<*AGROW>
    jobs{nbsuj}.spm.tools.cat.estwrite.nproc = 0;
    %     jobs{nbsuj}.spm.tools.cat.estwrite.opts.tpm = {fullfile(spm_dir,'tpm','TPM.nii,1')};
    %     jobs{nbsuj}.spm.tools.cat.estwrite.opts.affreg = 'mni';
    %     jobs{nbsuj}.spm.tools.cat.estwrite.opts.biasstr = 0.5;
    %     jobs{nbsuj}.spm.tools.cat.estwrite.extopts.APP = 1070;
    %     jobs{nbsuj}.spm.tools.cat.estwrite.extopts.LASstr = 0.5;
    %     jobs{nbsuj}.spm.tools.cat.estwrite.extopts.gcutstr = 0.5;
    %     jobs{nbsuj}.spm.tools.cat.estwrite.extopts.cleanupstr = 0.5;
    %     jobs{nbsuj}.spm.tools.cat.estwrite.extopts.registration.darteltpm = {fullfile(spm_dir,'toolbox','cat12','templates_1.50mm','Template_1_IXI555_MNI152.nii')};
    %     jobs{nbsuj}.spm.tools.cat.estwrite.extopts.registration.shootingtpm = {fullfile(spm_dir,'toolbox','cat12','templates_1.50mm','Template_0_IXI555_MNI152_GS.nii')};
    %     jobs{nbsuj}.spm.tools.cat.estwrite.extopts.registration.regstr = 0;
    %     jobs{nbsuj}.spm.tools.cat.estwrite.extopts.vox = 1.5;
    
    %defpar.GM   = [0 0 1 0]; % Unmodulated / modulated / native_space / dartel import
    
    % ROI
    if par.doROI==0
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.noROI = struct([]);
    end %else take the default
    
    % Surface
    jobs{nbsuj}.spm.tools.cat.estwrite.output.surface = par.doSurface;
    
    % TPM
    jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.warped = par.GM(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.mod    = par.GM(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.native = par.GM(3);
    if par.GM(4), jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.dartel = 2; end % 0==none, 1==rigid, 2==affine, 3==rigid+affine
    
    jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.warped = par.WM(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.mod    = par.WM(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.native = par.WM(3);
    if par.WM(4), jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.dartel = 2; end % 0==none, 1==rigid, 2==affine, 3==rigid+affine
    
    jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.warped = par.CSF(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.mod    = par.CSF(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.native = par.CSF(3);
    if par.CSF(4), jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.dartel = 2; end % 0==none, 1==rigid, 2==affine, 3==rigid+affine
    
    % Bias field, using SANML for denoising
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.native = par.bias(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.warped = par.bias(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.dartel = par.bias(3)*2;

    jobs{nbsuj}.spm.tools.cat.estwrite.output.label.native = par.label(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.label.warped = par.label(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.label.dartel = par.label(3)*2;
    
    if any(par.TPMC)
        jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.native = par.TPMC(1);
        jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.warped = par.TPMC(2);
        jobs{nbsuj}.spm.tools.cat.estwrite.output.TPMC.dartel = par.TPMC(3)*2;
    end

    jobs{nbsuj}.spm.tools.cat.estwrite.output.jacobian.warped = par.jacobian;
    
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
