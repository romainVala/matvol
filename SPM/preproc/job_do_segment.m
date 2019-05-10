function  jobs = job_do_segment(img,par)
% JOB_DO_SEGMENT - SPM:Spatial:Segment
%
% INPUT : img can be 'char' of volume(file), single-level 'cellstr' of volume(file), '@volume' array
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% for spm12 segment, if img{1} has several line then it is a multichannel
%
% 'par' allow you to specify which output to save  defaults are
%   par.GM   = [0 0 1 0]; % warped_space_Unmodulated(wc*) / warped_space_modulated(mwc*) / native_space(c*) / native_space_dartel_import(rc*)
%   par.WM   = [0 0 1 0];
%   par.CSF  = [0 0 1 0];
%   par.bias = [0 1]; % bias field / bias corrected image
%   par.warp = [1 1]; % warp field native->template / warp field native<-template
%
% See also get_subdir_regex get_subdir_regex_files exam exam.AddSerie exam.addVolume


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
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

% SPM:Spatial:Segment options
defpar.GM   = [0 0 1 0]; % warped_space_Unmodulated(wc*) / warped_space_modulated(mwc*) / native_space(c*) / native_space_dartel_import(rc*)
defpar.WM   = [0 0 1 0];
defpar.CSF  = [0 0 1 0];
defpar.bias = [0 1]; % bias field / bias corrected image
defpar.warp = [1 1]; % warp field native->template / warp field native<-template
defpar.TPMC       = [0 0 0] ;  % native normalize dartel  to write other  Tissu Probability Map Classes 

defpar.run     = 0;
defpar.display = 0;
defpar.redo    = 0;
defpar.sge     = 0;

defpar.auto_add_obj = 1;

defpar.jobname  = 'spm_segment';
defpar.walltime = '01:00:00';

par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end


%% Unzip : unzip volumes if required

if obj
    in_obj.unzip(par);
    img = in_obj.toJob;
else
    img = unzip_volume(img); % it makes the multi structure down ... arg <============ need to solve this
end


%% SPM:Spatial:Segment

% Check spm_version
[~ , r] = spm('Ver','spm');

skip = [];

for subj = 1:length(img)
    
    % Skip if y_ exist
    of = addprefixtofilenames(img(subj),'y_');
    if ~par.redo   &&   exist(of{1},'file')
        skip = [skip subj]; %#ok<*AGROW>
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,of{1});
    end
    
    if strfind(r,'SPM8')
        jobs{subj}.spm.spatial.preproc.data = img(subj);
        jobs{subj}.spm.spatial.preproc.output.GM = par.GM(1:3);  %there was no dartel import
        jobs{subj}.spm.spatial.preproc.output.WM = par.WM(1:3);
        jobs{subj}.spm.spatial.preproc.output.CSF =par.CSF(1:3);
        jobs{subj}.spm.spatial.preproc.output.biascor = 1;
        jobs{subj}.spm.spatial.preproc.output.cleanup = 0;
        jobs{subj}.spm.spatial.preproc.opts.tpm = {
            fullfile(spm('Dir'),'tpm','grey.nii')
            fullfile(spm('Dir'),'tpm','white.nii')
            fullfile(spm('Dir'),'tpm','csf.nii')
            };
        jobs{subj}.spm.spatial.preproc.opts.ngaus = [2;2;2;4];
        jobs{subj}.spm.spatial.preproc.opts.regtype = 'mni';
        jobs{subj}.spm.spatial.preproc.opts.warpreg = 1;
        jobs{subj}.spm.spatial.preproc.opts.warpco = 25;
        jobs{subj}.spm.spatial.preproc.opts.biasreg = 0.0001;
        jobs{subj}.spm.spatial.preproc.opts.biasfwhm = 60;
        jobs{subj}.spm.spatial.preproc.opts.samp = 3;
        jobs{subj}.spm.spatial.preproc.opts.msk = {''};
        
    elseif strfind(r,'SPM12')
        
        spm_dir = spm('Dir'); %fileparts(which ('spm'));
        %-----------------------------------------------------------------------
        % Job saved on 22-Aug-2014 11:36:31 by cfg_util (rev $Rev: 5797 $)
        % spm SPM - SPM12b (6080)
        %-----------------------------------------------------------------------
        for nbc = 1:size(img{subj},1)
            jobs{subj}.spm.spatial.preproc.channel(nbc).vols = cellstr(img{subj}(nbc,:));
            jobs{subj}.spm.spatial.preproc.channel(nbc).biasreg = 0.001;
            jobs{subj}.spm.spatial.preproc.channel(nbc).biasfwhm = 60;
            jobs{subj}.spm.spatial.preproc.channel(nbc).write = par.bias;
        end
        jobs{subj}.spm.spatial.preproc.tissue(1).tpm = {fullfile(spm_dir,'tpm','TPM.nii,1')};
        jobs{subj}.spm.spatial.preproc.tissue(1).ngaus = 1;
        jobs{subj}.spm.spatial.preproc.tissue(1).native = par.GM(3:4);
        jobs{subj}.spm.spatial.preproc.tissue(1).warped = par.GM(1:2);
        jobs{subj}.spm.spatial.preproc.tissue(2).tpm = {fullfile(spm_dir,'tpm','TPM.nii,2')};
        jobs{subj}.spm.spatial.preproc.tissue(2).ngaus = 1;
        jobs{subj}.spm.spatial.preproc.tissue(2).native = par.WM(3:4);
        jobs{subj}.spm.spatial.preproc.tissue(2).warped = par.WM(1:2);
        jobs{subj}.spm.spatial.preproc.tissue(3).tpm = {fullfile(spm_dir,'tpm','TPM.nii,3')};
        jobs{subj}.spm.spatial.preproc.tissue(3).ngaus = 2;
        jobs{subj}.spm.spatial.preproc.tissue(3).native = par.CSF(3:4);
        jobs{subj}.spm.spatial.preproc.tissue(3).warped = par.CSF(1:2);
        jobs{subj}.spm.spatial.preproc.tissue(4).tpm = {fullfile(spm_dir,'tpm','TPM.nii,4')};
        jobs{subj}.spm.spatial.preproc.tissue(4).ngaus = 3;
        jobs{subj}.spm.spatial.preproc.tissue(4).native = [par.TPMC(1) par.TPMC(3)];
        jobs{subj}.spm.spatial.preproc.tissue(4).warped = [par.TPMC(3) 0];
        jobs{subj}.spm.spatial.preproc.tissue(5).tpm = {fullfile(spm_dir,'tpm','TPM.nii,5')};
        jobs{subj}.spm.spatial.preproc.tissue(5).ngaus = 4;
        jobs{subj}.spm.spatial.preproc.tissue(5).native = [par.TPMC(1) par.TPMC(3)];
        jobs{subj}.spm.spatial.preproc.tissue(5).warped = [par.TPMC(3) 0];
        jobs{subj}.spm.spatial.preproc.tissue(6).tpm = {fullfile(spm_dir,'tpm','TPM.nii,6')};
        jobs{subj}.spm.spatial.preproc.tissue(6).ngaus = 2;
        jobs{subj}.spm.spatial.preproc.tissue(6).native = [par.TPMC(1) par.TPMC(3)];
        jobs{subj}.spm.spatial.preproc.tissue(6).warped = [par.TPMC(3) 0];
        jobs{subj}.spm.spatial.preproc.warp.mrf = 1;
        jobs{subj}.spm.spatial.preproc.warp.cleanup = 1;
        jobs{subj}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        jobs{subj}.spm.spatial.preproc.warp.affreg = 'mni';
        jobs{subj}.spm.spatial.preproc.warp.fwhm = 0;
        jobs{subj}.spm.spatial.preproc.warp.samp = 3;
        jobs{subj}.spm.spatial.preproc.warp.write = par.warp;
    end
end


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
    if par.bias(2), serieArray.addVolume(['^m'          tag ext],['m'          tag],1), end % Corrected
    if par.bias(1), serieArray.addVolume(['^BiasField_' tag ext],['BiasField_' tag],1), end % Field
    
    % GM
    if par.GM (3), serieArray.addVolume([  '^c1' tag ext],[  'c1' tag]), end % native_space(c*)
    if par.GM (4), serieArray.addVolume([ '^rc1' tag ext],[ 'rc1' tag]), end % native_space_dartel_import(rc*)
    if par.GM (1), serieArray.addVolume([ '^wc1' tag ext],[ 'wc1' tag]), end % warped_space_Unmodulated(wc*)
    if par.GM (2), serieArray.addVolume(['^mwc1' tag ext],['mwc1' tag]), end % warped_space_modulated(mwc*)
    
    % WM
    if par.WM (3), serieArray.addVolume([  '^c2' tag ext],[  'c2' tag]), end % native_space(c*)
    if par.WM (4), serieArray.addVolume([ '^rc2' tag ext],[ 'rc2' tag]), end % native_space_dartel_import(rc*)
    if par.WM (1), serieArray.addVolume([ '^wc2' tag ext],[ 'wc2' tag]), end % warped_space_Unmodulated(wc*)
    if par.WM (2), serieArray.addVolume(['^mwc2' tag ext],['mwc2' tag]), end % warped_space_modulated(mwc*)
    
    % CSF
    if par.CSF(3), serieArray.addVolume([  '^c3' tag ext],[  'c3' tag]), end % native_space(c*)
    if par.CSF(4), serieArray.addVolume([ '^rc3' tag ext],[ 'rc3' tag]), end % native_space_dartel_import(rc*)
    if par.CSF(1), serieArray.addVolume([ '^wc3' tag ext],[ 'wc3' tag]), end % warped_space_Unmodulated(wc*)
    if par.CSF(2), serieArray.addVolume(['^mwc3' tag ext],['mwc3' tag]), end % warped_space_modulated(mwc*)
    
end


end % function
