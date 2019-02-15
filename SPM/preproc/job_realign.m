function jobs = job_realign(in,par)
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
if isa(in,'volume')
    obj = 1;
    in_obj  = in;
end


%% defpar

defpar.prefix      = 'r';
defpar.file_reg    = '^f.*nii';
defpar.type        = 'estimate'; %estimate_and_reslice
defpar.which_write = [2 1]; %all + mean

defpar.jobname  = 'spm_realign';
defpar.walltime = '04:00:00';

defpar.auto_add_obj = 1;

defpar.sge     = 0;
defpar.run     = 0;
defpar.display = 0;
defpar.redo    = 0;

par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end


%%  SPM:Spatial:Realign:Estimate & Reslice

% estimate ? estimate_and_reslice ?
switch par.type
    case 'estimate'
        par.which_write = [0 1];
        
    case 'estimate_and_reslice'
        par.which_write = [2 1];
end

% obj : unzip if necesary
if obj
    in_obj.unzip(par);
    in = in_obj.toJob(1);
end

% nrSubject ?
if iscell(in{1})
    nrSubject = length(in);
else
    nrSubject = 1;
end

skip = [];

for subj = 1:nrSubject
    
    if obj
        if iscell(in{subj})
            subjectRuns = in{subj};
        else
            subjectRuns = in;
        end
    else
        if iscell(in{1})
            subjectRuns = get_subdir_regex_files(in{subj},par.file_reg);
            unzip_volume(subjectRuns); % unzip if necesary
            subjectRuns = get_subdir_regex_files(in{subj},par.file_reg);
        else
            subjectRuns = in;
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
            
            jobs{subj}.spm.spatial.realign.estwrite.data{run} = allVolumes;
            
        end
        
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


%% Add outputs objects

if obj && par.auto_add_obj
    
    serieArray      = [in_obj     .serie];
    serieArray_run1 = [in_obj(:,1).serie]; % the mean is only written in the run1
    tag             =  in_obj(1).tag;
    ext             = '.*.nii$';
    
    serieArray.     addVolume(['^' par.prefix tag ext],[par.prefix tag])
    serieArray_run1.addVolume(['^mean'        tag ext],['mean'     tag])
    
end


end % function
