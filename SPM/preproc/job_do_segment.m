function  jobs = job_do_segment(img,par)
%%  jobs = job_do_segment(img,par)
% for spm12 segment, if img{1} has several line then it is a multichanel
%
% par allow you to specify which output to save  defaults are
%   par.GM   = [0 0 1 0]; % Unmodulated / modulated / native_space dartel / import
%   par.WM   = [0 0 1 0];
%   par.CSF  = [0 0 1 0];
%   par.bias = [0 1]; % bias field / bias corrected image

if ~exist('par')
    par='';
end

defpar.GM   = [0 0 1 0]; % Unmodulated / modulated / native_space / dartel import
defpar.WM   = [0 0 1 0];
defpar.CSF  = [0 0 1 0];
defpar.bias = [0 1]; % bias field / bias corrected image
defpar.run = 0;
defpar.display=0;
defpar.redo=0;
defpar.sge = 0;

defpar.jobname='spm_segment';
defpar.walltime = '01:00:00';

par = complet_struct(par,defpar);


if ~iscell(img)
    img = cellstr(img);
end
img = unzip_volume(img); % it makes the multi structure down ... arg <============ need to solve this

%check spm_version
[v , r]=spm('Ver','spm');
skip=[];
for nbsuj = 1:length(img)
            
    %skip if y_ exist
    of = addprefixtofilenames(img(nbsuj),'y_');
    if ~par.redo
        if exist(of{1}),                skip = [skip nbsuj];     fprintf('skiping suj %d becasue %s exist\n',nbsuj,of{1});       end
    end

    if strfind(r,'SPM8')
        jobs{nbsuj}.spm.spatial.preproc.data = img(nbsuj);
        jobs{nbsuj}.spm.spatial.preproc.output.GM = par.GM(1:3);  %there was no dartel import
        jobs{nbsuj}.spm.spatial.preproc.output.WM = par.WM(1:3);
        jobs{nbsuj}.spm.spatial.preproc.output.CSF =par.CSF(1:3);
        jobs{nbsuj}.spm.spatial.preproc.output.biascor = 1;
        jobs{nbsuj}.spm.spatial.preproc.output.cleanup = 0;
        jobs{nbsuj}.spm.spatial.preproc.opts.tpm = {
            fullfile(spm('Dir'),'tpm','grey.nii')
            fullfile(spm('Dir'),'tpm','white.nii')
            fullfile(spm('Dir'),'tpm','csf.nii')
            };
        jobs{nbsuj}.spm.spatial.preproc.opts.ngaus = [2;2;2;4];
        jobs{nbsuj}.spm.spatial.preproc.opts.regtype = 'mni';
        jobs{nbsuj}.spm.spatial.preproc.opts.warpreg = 1;
        jobs{nbsuj}.spm.spatial.preproc.opts.warpco = 25;
        jobs{nbsuj}.spm.spatial.preproc.opts.biasreg = 0.0001;
        jobs{nbsuj}.spm.spatial.preproc.opts.biasfwhm = 60;
        jobs{nbsuj}.spm.spatial.preproc.opts.samp = 3;
        jobs{nbsuj}.spm.spatial.preproc.opts.msk = {''};
        
    elseif strfind(r,'SPM12')                

        spm_dir=spm('Dir'); %fileparts(which ('spm'));
        %-----------------------------------------------------------------------
        % Job saved on 22-Aug-2014 11:36:31 by cfg_util (rev $Rev: 5797 $)
        % spm SPM - SPM12b (6080)
        %-----------------------------------------------------------------------
        for nbc = 1:size(img{nbsuj},1)
            jobs{nbsuj}.spm.spatial.preproc.channel(nbc).vols = cellstr(img{nbsuj}(nbc,:));
            jobs{nbsuj}.spm.spatial.preproc.channel(nbc).biasreg = 0.001;
            jobs{nbsuj}.spm.spatial.preproc.channel(nbc).biasfwhm = 60;
            jobs{nbsuj}.spm.spatial.preproc.channel(nbc).write = par.bias;
        end
        jobs{nbsuj}.spm.spatial.preproc.tissue(1).tpm = {fullfile(spm_dir,'tpm','TPM.nii,1')};
        jobs{nbsuj}.spm.spatial.preproc.tissue(1).ngaus = 1;
        jobs{nbsuj}.spm.spatial.preproc.tissue(1).native = par.GM(3:4);
        jobs{nbsuj}.spm.spatial.preproc.tissue(1).warped = par.GM(1:2);
        jobs{nbsuj}.spm.spatial.preproc.tissue(2).tpm = {fullfile(spm_dir,'tpm','TPM.nii,2')};
        jobs{nbsuj}.spm.spatial.preproc.tissue(2).ngaus = 1;
        jobs{nbsuj}.spm.spatial.preproc.tissue(2).native = par.WM(3:4);
        jobs{nbsuj}.spm.spatial.preproc.tissue(2).warped = par.WM(1:2);
        jobs{nbsuj}.spm.spatial.preproc.tissue(3).tpm = {fullfile(spm_dir,'tpm','TPM.nii,3')};
        jobs{nbsuj}.spm.spatial.preproc.tissue(3).ngaus = 2;
        jobs{nbsuj}.spm.spatial.preproc.tissue(3).native = par.CSF(3:4);
        jobs{nbsuj}.spm.spatial.preproc.tissue(3).warped = par.CSF(1:2);
        jobs{nbsuj}.spm.spatial.preproc.tissue(4).tpm = {fullfile(spm_dir,'tpm','TPM.nii,4')};
        jobs{nbsuj}.spm.spatial.preproc.tissue(4).ngaus = 3;
        jobs{nbsuj}.spm.spatial.preproc.tissue(4).native = [1 0];
        jobs{nbsuj}.spm.spatial.preproc.tissue(4).warped = [0 0];
        jobs{nbsuj}.spm.spatial.preproc.tissue(5).tpm = {fullfile(spm_dir,'tpm','TPM.nii,5')};
        jobs{nbsuj}.spm.spatial.preproc.tissue(5).ngaus = 4;
        jobs{nbsuj}.spm.spatial.preproc.tissue(5).native = [1 0];
        jobs{nbsuj}.spm.spatial.preproc.tissue(5).warped = [0 0];
        jobs{nbsuj}.spm.spatial.preproc.tissue(6).tpm = {fullfile(spm_dir,'tpm','TPM.nii,6')};
        jobs{nbsuj}.spm.spatial.preproc.tissue(6).ngaus = 2;
        jobs{nbsuj}.spm.spatial.preproc.tissue(6).native = [0 0];
        jobs{nbsuj}.spm.spatial.preproc.tissue(6).warped = [0 0];
        jobs{nbsuj}.spm.spatial.preproc.warp.mrf = 1;
        jobs{nbsuj}.spm.spatial.preproc.warp.cleanup = 1;
        jobs{nbsuj}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        jobs{nbsuj}.spm.spatial.preproc.warp.affreg = 'mni';
        jobs{nbsuj}.spm.spatial.preproc.warp.fwhm = 0;
        jobs{nbsuj}.spm.spatial.preproc.warp.samp = 3;
        jobs{nbsuj}.spm.spatial.preproc.warp.write = [1 1];
    end
        end

jobs(skip)=[];
if isempty(jobs), return;end


if par.sge
    for k=1:length(jobs)
        j=jobs(k);        
        cmd = {'spm_jobman(''run'',j)'};
        varfile = do_cmd_matlab_sge(cmd,par);
        save(varfile{1},'j');
    end
end

if par.display
    spm_jobman('interactive',jobs);
    spm('show');
end

if par.run
    spm_jobman('run',jobs)
end
