function  jobs = job_do_segment(img,par)
% JOB_DO_SEGMENT - SPM:Spatial:Segment
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% for spm12 segment, if img{1} has several line then it is a multichannel
%
% 'par' allow you to specify which output to save  defaults are
%   par.GM   = [0 0 1 0]; % Unmodulated / modulated / native_space dartel / import
%   par.WM   = [0 0 1 0];
%   par.CSF  = [0 0 1 0];
%   par.bias = [0 1]; % bias field / bias corrected image
%
% See also get_subdir_regex get_subdir_regex_files


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    error('[%s]: not enough input arguments - image list is required',mfilename)
end

% Ensure the inputs are cellstrings, to avoid dimensions problems
img = cellstr(img);


%% defpar

% SPM:Spatial:Segment options
defpar.GM   = [0 0 1 0]; % Unmodulated / modulated / native_space / dartel import
defpar.WM   = [0 0 1 0];
defpar.CSF  = [0 0 1 0];
defpar.bias = [0 1]; % bias field / bias corrected image
defpar.warp = [1 1]; % warp field native->template / warp field native<-template

defpar.run     = 0;
defpar.display = 0;
defpar.redo    = 0;
defpar.sge     = 0;

defpar.jobname  = 'spm_segment';
defpar.walltime = '01:00:00';

par = complet_struct(par,defpar);


%% Unzip : unzip volumes if required

img = unzip_volume(img); % it makes the multi structure down ... arg <============ need to solve this


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
        jobs{subj}.spm.spatial.preproc.tissue(4).native = [1 0];
        jobs{subj}.spm.spatial.preproc.tissue(4).warped = [0 0];
        jobs{subj}.spm.spatial.preproc.tissue(5).tpm = {fullfile(spm_dir,'tpm','TPM.nii,5')};
        jobs{subj}.spm.spatial.preproc.tissue(5).ngaus = 4;
        jobs{subj}.spm.spatial.preproc.tissue(5).native = [1 0];
        jobs{subj}.spm.spatial.preproc.tissue(5).warped = [0 0];
        jobs{subj}.spm.spatial.preproc.tissue(6).tpm = {fullfile(spm_dir,'tpm','TPM.nii,6')};
        jobs{subj}.spm.spatial.preproc.tissue(6).ngaus = 2;
        jobs{subj}.spm.spatial.preproc.tissue(6).native = [0 0];
        jobs{subj}.spm.spatial.preproc.tissue(6).warped = [0 0];
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


end % function
