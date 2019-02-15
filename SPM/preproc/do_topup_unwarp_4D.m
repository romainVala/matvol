function job = do_topup_unwarp_4D(in,par)
% DO_TOPUP_UNWARP_4D - FSL:topup - FSL:unwarp
%
% INPUT : in can be 'char' of dir, multi-level 'cellstr' of dir, '@volume' array
%
% img is multilevel directory (see get_subdir_regex).
% The function will generate a mean for each runs (necessary to do topup on
% each run), then compute the warpfield, and finaly apply the warpfield to
% each run files (volumes + mean, normal scans + reversed phase scans).

% See also get_subdir_regex job_realign exam exam.AddSerie exam.addVolume


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
    in = in_obj.toJob(1);
end


%% defpar

defpar.todo               = 0;
defpar.subdir             = 'topup';
defpar.file_reg           = '^f.*nii';
defpar.fsl_output_format  = 'NIFTI';
defpar.do_apply           = [];

defpar.redo               = 0;
defpar.pct                = 0;
defpar.verbose            = 1;

defpar.auto_add_obj = 1;

par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end

parsge  = par.sge;
par.sge = -1; % only prepare commands

parverbose  = par.verbose;
par.verbose = 0; % don't print anything yet


%%  FSL:topup - FSL:unwarp

if iscell(in{1})
    nrSubject = length(in);
else
    nrSubject = 1;
end

job = cell(nrSubject,1);

fprintf('\n')

for subj=1:nrSubject
    
    % Extract subject name, and print it
    if obj
        subjectName = get_parent_path(get_parent_path(in{subj}(1)));
    else
        subjectName = get_parent_path(in{subj}(1));
    end
    
    % Echo in terminal & initialize job_subj
    fprintf('[%s]: Preparing JOB %d/%d for %s \n', mfilename, subj, nrSubject, subjectName{1});
    job_subj = {sprintf('#################### JOB %d/%d for %s #################### \n', subj, nrSubject, subjectName{1})}; % initialize
    
    if obj
        % Fetch current subject images files
        runList = in_obj(subj,:).getPath';
    else
        % Fetch current subject images files
        runList = get_subdir_regex_files(in{subj},par.file_reg,1);
    end
    
    
    % Create inside the subject dir runName "topup" dire, which will be our
    % working directory
    topup_outdir = r_mkdir(subjectName,par.subdir);
    
    for run = 1:length(runList)
        
        % if realign & reslice runList is 'rf' volume whereas the mean is meanf
        runName = runList{run}(1,:);
        [pathstr, name, ext] = fileparts(runName);
        if strcmp(name(1),'r')
            runName = fullfile(pathstr,[name(2:end) ext]);
        end
        
        % Generate if needed, a mean image for all runs (necessary for topup)
        mean_files_cellstr = addprefixtofilenames({runName},'mean');
        if ~exist(mean_files_cellstr{1},'file')
            [ mean_files_cellstr{1}, job_subj ] = do_fsl_mean(runList(run),mean_files_cellstr{1},par, job_subj);
        end
        
        % Is the orientation of all runs coherent ?
        if run>1
            if compare_orientation(fmean(1),runList(run)) == 0
                warning('[%s]: WARNING reslicing mean image %s \n', mfilename, mean_files_cellstr{1});
                [ resliced_mean, job_subj ]= do_fsl_reslice( mean_files_cellstr(1),fmean(1),'', job_subj);
                mean_files_cellstr(1) = resliced_mean;
            end
        end
        
        runList{run}=char([cellstr(char(runList(run)));mean_files_cellstr]);
        fmean(run) = mean_files_cellstr(1); %#ok<AGROW>
        
    end
    
    fout = addsuffixtofilenames(topup_outdir,'/4D_orig_topup_movpar.txt');
    
    if exist(fout{1},'file') && ~par.redo
        fprintf('[%s]: skiping topup estimate because %s exists \n',mfilename,fout{1})
    else
        
        %ACQP=topup_param_from_nifti_cenir(runList,topup_outdir)
        try
            ACQP=topup_param_from_json_cenir(fmean,topup_outdir);
        catch err
            warning(err.message)
            ACQP=topup_param_from_nifti_cenir(fmean,topup_outdir);
        end
        if size(unique(ACQP),1)<2
            error('all the serie have the same phase direction can not do topup')
        end
        
        fo = addsuffixtofilenames(topup_outdir,'/4D_orig');
        
        par.checkorient=0; %give error if not same orient : don't want to check
        
        job_subj = do_fsl_merge(fmean,fo{1},par, job_subj);
        job_subj = do_fsl_topup(fo,par, job_subj);
        
    end
    
    fo = addsuffixtofilenames(topup_outdir,'/4D_orig_topup');
    
    if isempty(par.do_apply)
        par.do_apply = ones(size(runList));
    end
    
    for run=1:length(runList)
        %no because length is the same  realind = ceil(run/2); % because runList ad the mean
        %par.index=realind;
        
        par.index=run;
        if par.do_apply(run)
            for volume_idx = 1:size(runList{run},1)
                job_subj = do_fsl_apply_topup(runList{run}(volume_idx,:),fo,par, job_subj);
            end
        end
        
    end
    
    job{subj} = char(job_subj);
    
end % for - subject


%% Executes th prepared commands

par.sge     = parsge;
par.verbose = parverbose;

job = do_cmd_sge(job,par);


%% Add outputs objects

if obj && par.auto_add_obj
    
    serieArray      = [in_obj.serie];
    tag             =  in_obj(1).tag;
    
    switch defpar.fsl_output_format
        case 'NIFTI'
            ext = '.*.nii';
        case 'NIFTI_GZ'
            ext = '.*.nii.gz';
    end
    
    serieArray.addVolume(['^ut'     tag ext],['ut'     tag])
    
    if strcmp(tag(1),'r')
        tag = tag(2:end);
    end
    
    serieArray.addVolume(['^mean'   tag ext],['mean'   tag])
    serieArray.addVolume(['^utmean' tag ext],['utmean' tag])
    
end


end % function
