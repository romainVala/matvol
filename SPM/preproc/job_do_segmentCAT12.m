function  jobs = job_do_segmentCAT12(img,par)
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

defpar.GM   = [0 1 1 1]; % Unmodulated / modulated / native_space / dartel import
%first one not possible, but keep for compatibility with spm12 job_segment
defpar.WM   = [0 1 1 1];
defpar.CSF  = [0 1 1 1];
defpar.bias = [1 1 0] ; % native normalize dartel     [0 1]; % bias field / bias corrected image
defpar.def_field = [1 1]; % deformation field to write [y iy]
defpar.jacobian = 0; %write jacobian determinant in normalize space
defpar.run = 0;
defpar.display=0;
defpar.redo=0;
defpar.sge = 0;
defpar.doROI = 1;
defpar.doSurface =1;
defpar.subfolder=0; % all results in the same subfolder

defpar.jobname='spm_segmentCAT';
defpar.walltime = '02:00:00';
par = complet_struct(par,defpar);
defpar.cmd_prepend = sprintf('global cat; cat_defaults; cat.extopts.subfolders=%d; cat.extopts.expertgui=1;clear defaults; spm_jobman(''initcfg'');',...
    par.subfolder);

par = complet_struct(par,defpar);

%to make expert mode active if not done
global cat
if cat.extopts.expertgui==0
    eval(par.cmd_prepend)
end

if ~iscell(img)
    img = cellstr(img);
end
img = unzip_volume(img);

%check toolbox install
a=which('cat12')
if isempty(a), error('cat12.m not found you must install the toolbox');end

skip=[];
for nbsuj = 1:length(img)
    
    %skip if y_ exist
    %     of = addprefixtofilenames(img(nbsuj),'y_');
    %     if ~par.redo
    %         if exist(of{1}),                skip = [skip nbsuj];     fprintf('skiping suj %d becasue %s exist\n',nbsuj,of{1});       end
    %     end
    
    spm_dir=spm('Dir'); %fileparts(which ('spm'));
    jobs{nbsuj}.spm.tools.cat.estwrite.data = cellstr(img{nbsuj});
    %     jobs{nbsuj}.spm.tools.cat.estwrite.nproc = 0;
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
    
    if par.doROI==0
        jobs{nbsuj}.spm.tools.cat.estwrite.output.ROImenu.noROI = struct([]);
    end %else take the default
    
    jobs{nbsuj}.spm.tools.cat.estwrite.output.surface = par.doSurface;
    jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.native = par.GM(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.mod = par.GM(2);
    if par.GM(4)
        jobs{nbsuj}.spm.tools.cat.estwrite.output.GM.dartel = 2;
    end
    jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.native = par.WM(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.mod = par.WM(2);
    if par.WM(4)
        jobs{nbsuj}.spm.tools.cat.estwrite.output.WM.dartel = 2;
    end
    jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.native = par.CSF(3);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.mod = par.CSF(2);
    if par.CSF(4)
        jobs{nbsuj}.spm.tools.cat.estwrite.output.CSF.dartel = 2;
    end
    
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.native = par.bias(1);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.warped = par.bias(2);
    jobs{nbsuj}.spm.tools.cat.estwrite.output.bias.dartel = par.bias(3)*2;
    
    jobs{nbsuj}.spm.tools.cat.estwrite.output.jacobian.warped = par.jacobian;
    jobs{nbsuj}.spm.tools.cat.estwrite.output.warps = par.def_field;
    
    
end



[ jobs ] = job_ending_rountines( jobs, skip, par );
%
% if par.sge
%     cmd{1} = sprintf('%s \n spm_jobman(''run'',j)',par.cmd_prepend);
%     cmd = repmat(cmd,size(jobs));
%
%     varfile = do_cmd_matlab_sge(cmd,par)
%
%     for k=1:length(jobs)
%         j=jobs(k);
%         %cmd{1} = sprintf('%s \n spm_jobman(''run'',j)',par.cmd_prepend);
%         %varfile = do_cmd_matlab_sge(cmd,par);
%         save(varfile{k},'j');
%     end
% end
%
% if par.display
%     spm_jobman('interactive',jobs);
%     spm('show');
% end
%
% if par.run
%     spm_jobman('run',jobs)
% end
