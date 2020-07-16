function jobs = job_realign_and_unwarp(fonc_dir, fmdir, par)
% JOB_REALIGN - SPM:Spatial:Realign:Estimate & Reslice
%
% INPUT : fin can be 'char' of dir, multi-level 'cellstr' of dir, '@volume' array
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also get_subdir_regex get_subdir_regex_files exam exam.AddSerie exam.addVolume


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - in is required',mfilename)
end

obj = 0;
if isa(fonc_dir,'volume')
    obj = 1;
    volumeArray = fonc_dir;
end


%% defpar

% SPM:Spatial:Realign:Estimate & Reslice
defpar.prefix      = 'r';
defpar.file_reg    = '^f.*nii';
defpar.which_write = [2 1]; %all + mean

% cluster
defpar.jobname  = 'spm_realign';
defpar.walltime = '04:00:00';

% matvol classics
defpar.sge          = 0;
defpar.run          = 1;
defpar.display      = 0;
defpar.redo         = 0;
defpar.auto_add_obj = 1;
defpar.mask = 1;
defpar.use_JSON_regex = 'json';
defpar.fanat = '';

par = complet_struct(par,defpar);

%%  SPM:Spatial:Realign & Unwarp

% obj : unzip if necesary
if obj
    volumeArray.unzip(par);
    fonc_dir = volumeArray.toJob(1);
end

% nrSubject ?
if iscell(fonc_dir{1})
    nrSubject = length(fonc_dir);
else
    nrSubject = 1;
end

skip = [];

for subj = 1:nrSubject
    
    if obj
        if iscell(fonc_dir{subj})
            subjectRuns = fonc_dir{subj};
        else
            subjectRuns = fonc_dir;
        end
    else
        if iscell(fonc_dir{1})
            subjectRuns = gfile(fonc_dir{subj},par.file_reg);
            unzip_volume(subjectRuns); % unzip if necesary
            subjectRuns = gfile(fonc_dir{subj},par.file_reg);
        else
            subjectRuns = fonc_dir;
        end
    end
    
    %skip if mean exist
    mean_filenames_cellstr = addprefixtofilenames(subjectRuns(1),'mean');
    if ~par.redo   &&   exist(mean_filenames_cellstr{1},'file')
        skip = [skip subj];
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,mean_filenames_cellstr{1});
    end
    
    for run = 1:length(subjectRuns)

        currentRun = cellstr(subjectRuns{run}) ;
        
        [es, pdir, TE, totes] = get_EPI_param_from_json(currentRun);
        switch pdir
            case {'-y'}
                pdir = -1
            case {'y'}
                pdir = 1
            otherwise
                error('wrong phase encoding direction')
        end
        
        %echo time diff from field map magnetude
        json = gfile(fmdir{subj}{1},'json')
        json=cellstr(char(json))
        res = get_string_from_json(json, {'EchoTime'}, {'num'});
        fm_TE(1) = min(res{1}{1}, res{2}{1});
        fm_TE(2) = max(res{1}{1}, res{2}{1});
        
        
        %skip if last one exist
        lastrun_filenames_cellstr = addprefixtofilenames(currentRun(end),par.prefix);
        if ~par.redo   &&   exist(lastrun_filenames_cellstr{1},'file')
            skip = [skip subj];
            fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,lastrun_filenames_cellstr{1});
            
        else
            
            clear allVolumes
            
            if length(currentRun) == 1 % 4D file (*.nii)
                allVolumes = spm_select('expand',currentRun);
            else
                allVolumes = currentRun;
            end
            fphase = gfile(fmdir{subj}{2},'^s_S.*nii',1);
            fmag   = gfile(fmdir{subj}{1},'^s_S.*nii',2);
            fmag = {deblank(fmag{1}(1,:))};
            
            fphase = unzip_volume(fphase);
            fmag = unzip_volume(fmag);
            
            fdisp = fphase;
            fdisp = addprefixtofilenames(fdisp,'vdm5_sc');
            
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = fphase;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = fmag;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.et = fm_TE;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.maskbrain = 1;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.blipdir = pdir;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.tert = totes;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.epifm = 0;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.ajm = 0;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.method = 'Mark3D';
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.fwhm = 10;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.pad = 0;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.ws = 1;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.template = {'/network/lustre/iss01/cenir/software/irm/spm12/toolbox/FieldMap/T1.nii'};
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.fwhm = 5;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.nerode = 2;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.ndilate = 4;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.thresh = 0.5;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.reg = 0.02;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.session.epi = allVolumes;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1;
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'session';
            jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 1;
            
            if ~isempty(par.fanat)
                jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.anat = par.fanat{subj};
                jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 1;
            else
                jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.anat = '';
                jobs{2*subj-1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0;

            end
            
            %job realign
            jobs{2*subj}.spm.spatial.realignunwarp.data.scans = allVolumes;
            jobs{2*subj}.spm.spatial.realignunwarp.data.pmscan(1) = fdisp;
            jobs{2*subj}.spm.spatial.realignunwarp.eoptions.quality = 1;
            jobs{2*subj}.spm.spatial.realignunwarp.eoptions.sep = 4;
            jobs{2*subj}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
            jobs{2*subj}.spm.spatial.realignunwarp.eoptions.rtm = 1; %register to mean
            jobs{2*subj}.spm.spatial.realignunwarp.eoptions.einterp = 2;
            jobs{2*subj}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
            jobs{2*subj}.spm.spatial.realignunwarp.eoptions.weight = '';
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.jm = 0;
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.sot = [];
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.rem = 1;
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.noi = 5;
            jobs{2*subj}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
            jobs{2*subj}.spm.spatial.realignunwarp.uwroptions.uwwhich = par.which_write; %all + mean images
            jobs{2*subj}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
            jobs{2*subj}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
            jobs{2*subj}.spm.spatial.realignunwarp.uwroptions.mask =  par.mask;
            jobs{2*subj}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';

            
        end
        
    end
    
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


%% Add outputs objects
%TODO

end % function
