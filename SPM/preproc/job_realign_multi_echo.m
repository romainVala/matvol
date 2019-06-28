function jobs = job_realign_multi_echo( in, par )
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

defpar.file_reg    = '^ae.*nii'; % Slice Timing correction applied
defpar.prefix      = 'r';

defpar.jobname  = 'spm_realign_multi_echo';
defpar.walltime = '02:00:00'; % HH:MM:SS
defpar.mem      = 2000;       % MB

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


%% Realign multi-echo

% For multi-echo dataset, the recomended strategy is :
%
% 1) Slice Timing Correction
% 2) Realign all first (shortest) echos
% 3) Use the same transformation to all other echos
% 4) TEDANA (python)
% 5+) continue with processing, such as distorsion correcton, coregistration, normalization, ...
%
% This job is doing step 2) and 3)

% obj : unzip if necesary
if obj
    in_obj.unzip(par);
    in = in_obj.toJob(2);
end

% nrSubject ?
if iscell(in{1})
    if obj
        nSubj = size(in,1);
    else
        nSubj = length(in);
    end
else
    nSubj = 1;
end

skip         = [];
jobs_all     = cell(1,nSubj);
jobs_realign = cell(0);

for iSubj = 1 : nSubj
    
    if obj
        subjectRuns = in(iSubj,:);
        subjectRuns = cellfun(@char,subjectRuns,'UniformOutput',0)';
        subjectRuns = subjectRuns(~cellfun(@isempty, subjectRuns)); % remove empty lines
    else
        if iscell(in{1})
            subjectRuns = get_subdir_regex_files(in{iSubj},par.file_reg);
            unzip_volume(subjectRuns); % unzip if necesary
            subjectRuns = get_subdir_regex_files(in{iSubj},par.file_reg);
        else
            subjectRuns = in;
        end
    end
    
    nRun = length(subjectRuns);
    fprintf('[%s]: %d runs for %s \n', mfilename, nRun, in_obj(iSubj,1,1).exam.path)
    
    %----------------------------------------------------------------------
    % Realign
    %----------------------------------------------------------------------
    
    % skip if mean exist
    mean_filenames_cellstr = addprefixtofilenames(subjectRuns(1),'mean');
    if ~par.redo   &&   exist(mean_filenames_cellstr{1},'file')
        skip = [skip iSubj]; %#ok<AGROW>
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,iSubj,mean_filenames_cellstr{1});
    end
    
    for iRun = 1 : nRun
        
        currentRuns = cellstr(subjectRuns{iRun}) ;
        
        % skip if last one exist
        lastrun_filenames_cellstr = addprefixtofilenames(currentRuns(end),par.prefix);
        if ~par.redo   &&   exist(lastrun_filenames_cellstr{1},'file')
            skip = [skip iSubj]; %#ok<AGROW>
            fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,iSubj,lastrun_filenames_cellstr{1});
        else
            jobs_realign{1}.spm.spatial.realign.estimate.data{iRun} = spm_select('expand',currentRuns(1)); % realign ehco 1
        end
        
    end % iRun
    
    jobs_realign{1}.spm.spatial.realign.estimate.eoptions.quality = 1;
    jobs_realign{1}.spm.spatial.realign.estimate.eoptions.sep     = 4;
    jobs_realign{1}.spm.spatial.realign.estimate.eoptions.fwhm    = 5;
    jobs_realign{1}.spm.spatial.realign.estimate.eoptions.rtm     = 1; % 0 = register to first, 1 = register to mean
    jobs_realign{1}.spm.spatial.realign.estimate.eoptions.interp  = 2;
    jobs_realign{1}.spm.spatial.realign.estimate.eoptions.wrap    = [0 0 0];
    jobs_realign{1}.spm.spatial.realign.estimate.eoptions.weight  = '';
    
    jobs_copy    = cell(1,nRun);
    jobs_reslice = cell(1);
    j_cp         = 0;
    for iRun = 1 : nRun
        
        currentRuns = cellstr(subjectRuns{iRun}) ;
        
        %------------------------------------------------------------------
        % Copy .mat
        %------------------------------------------------------------------
        
        [e1_pth,e1_nam,~] = spm_fileparts(currentRuns{1});
        e1_mat            = fullfile(e1_pth,[e1_nam '.mat']);
        
        for iEcho = 2 : length(currentRuns)
            
            j_cp = j_cp + 1;
            
            jobs_copy{j_cp}.cfg_basicio.file_dir.file_ops.file_move.files                            = {e1_mat};
            jobs_copy{j_cp}.cfg_basicio.file_dir.file_ops.file_move.action.copyren.copyto            = {e1_pth};
            jobs_copy{j_cp}.cfg_basicio.file_dir.file_ops.file_move.action.copyren.unique            = false;
            
            [~,ei_nam,~] = spm_fileparts(currentRuns{iEcho});
            
            jobs_copy{j_cp}.cfg_basicio.file_dir.file_ops.file_move.action.copyren.patrep.pattern = e1_nam;
            jobs_copy{j_cp}.cfg_basicio.file_dir.file_ops.file_move.action.copyren.patrep.repl    = ei_nam;
            
        end % iEcho
        
        
        
    end % iRun
    
    %------------------------------------------------------------------
    % Reslice
    %------------------------------------------------------------------
    
    jobs_reslice{1}.spm.spatial.realign.write.data            = cellstr(char(subjectRuns));
    jobs_reslice{1}.spm.spatial.realign.write.roptions.which  = [2 1]; % all + mean image
    jobs_reslice{1}.spm.spatial.realign.write.roptions.interp = 4;
    jobs_reslice{1}.spm.spatial.realign.write.roptions.wrap   = [0 0 0];
    jobs_reslice{1}.spm.spatial.realign.write.roptions.mask   = 1;
    jobs_reslice{1}.spm.spatial.realign.write.roptions.prefix = par.prefix;
    
    jobs_all{iSubj} = { jobs_realign jobs_copy jobs_reslice };
    
end % iSubj


%% Other routines

% Manage jobs to skip here, because we have to "concatenate" them.
jobs_all(skip) = [];

% Now expand all jobs
jobs = cell(0);
for iJob = 1 : length(jobs_all)
    
    % Concat for SGE : VERY IMPORTANT
    concat = sum(cellfun(@length, jobs_all{iJob}));
    if isfield(par,'concat') && (par.concat ~= concat)
        error('all subjs do not have the same number of echos, par.sge or par.pct will not be working correctly, DO NOT DO IT')
    end
    par.concat = concat;
    
    for jJob = 1 : length(jobs_all{iJob})
        jobs = [ jobs jobs_all{iJob}{jJob} ]; %#ok<AGROW>
    end
    
end

[ jobs ] = job_ending_rountines( jobs, [], par );

if par.sge
    fprintf('[%s]: Please check the concatenation of jobs \n', mfilename)
end


%% Add outputs objects

if obj && par.auto_add_obj && par.run
    
    serieArray_run1 = [in_obj(:,1).serie]; % the mean is only written in the run1
    tag             =  {in_obj.tag};
    ext             = '.*.nii$';
    for iVol = 1 : numel(in_obj)
        in_obj(iVol).serie.addVolume(['^' par.prefix tag{iVol} ext],[par.prefix tag{iVol}])
    end
    serieArray_run1.addVolume(['^mean' tag{1} ext],['mean' tag{1}])
    
end


end % function
