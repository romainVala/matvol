function job = do_topup_unwarp_4D(dirFonc,par)
% DO_TOPUP_UNWARP_4D - FSL:topup - FSL:unwarp
% img is multilevel directory (see get_subdir_regex).
% The function will generate a mean for each runs (necessary to do topup on
% each run), then compute the warpfield, and finaly apply the warpfield to
% each run files (volumes + mean, normal scans + reversed phase scans).

% See also get_subdir_regex job_realign

%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.todo               = 0;
defpar.subdir             = 'topup';
defpar.file_reg           = '^f.*nii';
defpar.fsl_output_format  = 'NIFTI';
defpar.do_apply           = [];
defpar.redo               = 0;
defpar.pct                = 0;

par = complet_struct(par,defpar);

parsge = par.sge;
par.sge = -1; % only prepare commands


%%  FSL:topup - FSL:unwarp

if iscell(dirFonc{1})
    nrSubject = length(dirFonc);
else
    nrSubject = 1;
end

job = cell(0);

for subj=1:nrSubject
    
    job_subj = '';
    
    % Extract subject name, and print it
    subjectName = get_parent_path(dirFonc{subj}(1));
    fprintf('[%s]: Preparing %s \n\n', mfilename, subjectName{1});
    
    % Fetch current subject images files
    runList = get_subdir_regex_files(dirFonc{subj},par.file_reg);
    
    % Create inside the subject dir runName "topup" dire, which will be our
    % working directory
    topup_outdir = r_mkdir(subjectName,par.subdir);
    
    clear job_do_fsl_mean
    
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
                [ resliced_mean, job_subj ]= do_fsl_reslice( mean_files_cellstr(1),fmean(1), job_subj);
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
            job_subj = do_fsl_apply_topup(runList(run),fo,par, job_subj);
        end
        
    end
    
    job(end+1,1) = {char(job_subj)};
    
    disp(job{end})
    
end % for - subject


par.sge = parsge;

job = do_cmd_sge(job,par);


end % function
