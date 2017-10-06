function jobs = job_realign(dirFonc,par)
% JOB_REALIGN - SPM:Spatial:Realign:Estimate & Reslice
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also get_subdir_regex get_subdir_regex_files


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.prefix      = 'r';
defpar.file_reg    = '^f.*nii';
defpar.type        = 'estimate'; %estimate_and_reslice
defpar.which_write = [2 1]; %all + mean

defpar.jobname  = 'spm_realign';
defpar.walltime = '04:00:00';

defpar.sge     = 0;
defpar.run     = 0;
defpar.display = 0;
defpar.redo    = 0;

par = complet_struct(par,defpar);



%%  SPM:Spatial:Realign:Estimate & Reslice

% estimate ? estimate_and_reslice ?
switch par.type
    case 'estimate'
        par.which_write = [0 1];
        
    case 'estimate_and_reslice'
        par.which_write = [2 1];
end

% nrSubject ?
if iscell(dirFonc{1})
    nrSubject = length(dirFonc);
else
    nrSubject = 1;
end

skip = [];

for subj = 1:nrSubject
    
    if iscell(dirFonc{1}) %
        subjectRuns = get_subdir_regex_files(dirFonc{subj},par.file_reg);
        unzip_volume(subjectRuns);
        subjectRuns = get_subdir_regex_files(dirFonc{subj},par.file_reg);
        
    else
        subjectRuns = dirFonc;
    end
    
    %skip if mean exist
    mean_filenames_cellstr = addprefixtofilenames(subjectRuns(1),'mean');
    if ~par.redo   &&   exist(mean_filenames_cellstr{1},'file')
        skip = [skip subj];
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,mean_filenames_cellstr{1});
    end
    
    for run = 1:length(subjectRuns)
        currentRun = cellstr(subjectRuns{run}) ;
        clear allVolumes
        
        if length(currentRun) == 1 % 4D file (*.nii)
            nrVolumes = spm_vol(currentRun{1});
            for vol = 1:length(nrVolumes)
                allVolumes{vol,1} = sprintf('%s,%d',currentRun{1},vol);
            end
        else
            allVolumes = currentRun;
        end
        
        jobs{subj}.spm.spatial.realign.estwrite.data{run} = allVolumes;
        
    end
    
    %skip if last one exist
    lastrun_filenames_cellstr = addprefixtofilenames(currentRun(end),par.prefix);
    if ~par.redo   &&   exist(lastrun_filenames_cellstr{1},'file')
        skip = [skip subj];
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,lastrun_filenames_cellstr{1});
    end
    
    jobs{subj}.spm.spatial.realign.estwrite.eoptions.quality = 1; %#ok<*AGROW>
    jobs{subj}.spm.spatial.realign.estwrite.eoptions.sep = 4;
    jobs{subj}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
    jobs{subj}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
    jobs{subj}.spm.spatial.realign.estwrite.eoptions.interp = 2;
    jobs{subj}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
    jobs{subj}.spm.spatial.realign.estwrite.eoptions.weight = '';
    jobs{subj}.spm.spatial.realign.estwrite.roptions.which = par.which_write; %all + mean images
    jobs{subj}.spm.spatial.realign.estwrite.roptions.interp = 4;
    jobs{subj}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
    jobs{subj}.spm.spatial.realign.estwrite.roptions.mask = 1;
    jobs{subj}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
    
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


end % function
