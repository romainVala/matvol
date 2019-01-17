function jobs = job_first_level_specify(dirFonc,dirStats,onsets,par)
% JOB_FIRST_LEVEL_SPECIFY - SPM:Stats:fMRI model specification


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.file_reg = '^s.*nii';
defpar.rp       = 0;
defpar.rp_regex = '^rp.*txt';
defpar.mask_thr = 0.8;
defpar.cvi      = 'AR(1)'; % 'AR(1)' / 'FAST' / 'none'

defpar.jobname  = 'spm_glm';
defpar.walltime = '04:00:00';

defpar.sge      = 0;
defpar.run      = 0;
defpar.display  = 0;
defpar.redo     = 0;

par = complet_struct(par,defpar);


%% SPM:Stats:fMRI model specification

if iscell(dirFonc{1})
    nrSubject = length(dirFonc);
else
    nrSubject=1;
end

skip = [];

for subj = 1:nrSubject
    
    spm_file = char(addsuffixtofilenames(dirStats(subj),'SPM.mat'));
    if ~par.redo   &&  exist(spm_file,'file')
        skip = [skip subj];
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,subj,spm_file);
    else
        
        % Check of all TR are the same for each run
        if ~isfield(par,'TR')
            
            jsons = get_subdir_regex_files( dirFonc{subj} , '^dic.*json$' );
            if iscell(dirFonc{1})
                assert( length(dirFonc{subj}) == length(jsons) , 'dic.*json were no found in all volumes' )
            else
                assert( length(dirFonc) == length(jsons) , 'dic.*json were no found in all volumes' )
            end
            % Multiple json files ? Like multi-echo ?
            for j = 1 : length(jsons)
                jsons{j} = jsons{j}(1,:); % only keep the first echo
            end
            [ TRs ] = get_string_from_json( jsons , 'RepetitionTime' , 'numeric' );
            allTR = nan(size(TRs));
            for idx = 1 : length(allTR)
                allTR(idx) = TRs{idx}{1};
            end
            if iscell(dirFonc{1})
                assert( all( allTR(1)==allTR ) , 'TR is not the same for each run : %s' , dirFonc{subj}{:} )
            else
                assert( all( allTR(1)==allTR ) , 'TR is not the same for each run : %s' , dirFonc{:} )
            end
            
            % Define TR
            par.TR = allTR(1)/1000; % convert milliseconds into seconds
            
        end
        
        %     if iscell(dirFonc{1})
        subjectRuns = get_subdir_regex_files(dirFonc{subj},par.file_reg);
        unzip_volume(subjectRuns);
        subjectRuns = get_subdir_regex_files(dirFonc{subj},par.file_reg,struct('verbose',0));
        if par.rp
            fileRP = get_subdir_regex_files(dirFonc{subj},par.rp_regex);
        end
        %     else
        %         subjectRuns = dirFonc;
        %     end
        
        % When onsets are inside the .mat file
        if ~ isstruct(onsets{1})
            fonset = cellstr(char(onsets(subj)));
        end
        
        for run = 1:length(subjectRuns)
            currentRun = cellstr(subjectRuns{run}) ;
            clear allVolumes
            
            if length(currentRun) == 1 %4D file
                allVolumes = spm_select('expand',currentRun);
            else
                allVolumes = currentRun;
            end
            jobs{subj}.spm.stats.fmri_spec.sess(run).scans = allVolumes; %#ok<*AGROW>
            jobs{subj}.spm.stats.fmri_spec.sess(run).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
            jobs{subj}.spm.stats.fmri_spec.sess(run).multi = {''};
            if isstruct(onsets{1})
                jobs{subj}.spm.stats.fmri_spec.sess(run).cond = onsets{run};
            else
                jobs{subj}.spm.stats.fmri_spec.sess(run).multi = fonset(run);
            end
            
            if par.rp
                jobs{subj}.spm.stats.fmri_spec.sess(run).multi_reg = fileRP(run);
            else
                jobs{subj}.spm.stats.fmri_spec.sess(run).multi_reg = {''};
            end
            
            jobs{subj}.spm.stats.fmri_spec.sess(run).regress = struct('name', {}, 'val', {});
            jobs{subj}.spm.stats.fmri_spec.sess(run).hpf = 128;
            
        end % run
        
        jobs{subj}.spm.stats.fmri_spec.timing.units = 'secs';
        jobs{subj}.spm.stats.fmri_spec.timing.RT = par.TR;
        jobs{subj}.spm.stats.fmri_spec.timing.fmri_t = 16;
        jobs{subj}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
        
        jobs{subj}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
        jobs{subj}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        jobs{subj}.spm.stats.fmri_spec.volt = 1;
        jobs{subj}.spm.stats.fmri_spec.global = 'None';
        jobs{subj}.spm.stats.fmri_spec.mthresh = par.mask_thr;
        jobs{subj}.spm.stats.fmri_spec.mask = {''};
        jobs{subj}.spm.stats.fmri_spec.cvi = par.cvi;
        
    end % SPM.mat exists ?
    
    jobs{subj}.spm.stats.fmri_spec.dir = dirStats(subj);
    
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


end % function
