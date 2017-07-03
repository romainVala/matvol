function jobs = job_first_level_specify(dirFonc,dirStats,onsets,par)
% JOB_FIRST_LEVEL_SPECIFY - SPM:Stats:fMRI model specification


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.file_reg = '^s.*nii';
defpar.rp       = 0;

defpar.jobname  = 'spm_glm';
defpar.walltime = '04:00:00';

defpar.sge      = 0;
defpar.run      = 0;
defpar.display  = 0;

par.redo        = 0;

par = complet_struct(par,defpar);

if ~isfield(par,'TR')
    error('par structure must have non empty TR field.')
end


%% SPM:Stats:fMRI model specification

if iscell(dirFonc{1})
    nrSubject = length(dirFonc);
else
    nrSubject=1;
end

for subj = 1:nrSubject
    
    if iscell(dirFonc{1})
        subjectRuns = get_subdir_regex_files(dirFonc{subj},par.file_reg);
        unzip_volume(subjectRuns);
        subjectRuns = get_subdir_regex_files(dirFonc{subj},par.file_reg);
        if par.rp
            fileRP = get_subdir_regex_files(dirFonc{subj},'^rp.*txt');
        end
    else
        subjectRuns = dirFonc;
    end
    
    % When onsets are inside the .mat file
    if ~ isstruct(onsets{1})
        fonset = cellstr(char(onsets(subj)));
    end
    
    for run = 1:length(subjectRuns)
        currentRun = cellstr(subjectRuns{run}) ;
        clear allVolumes
        
        if length(currentRun) == 1 %4D file
            nrVoumes = spm_vol(currentRun{1});
            for vol=1:length(nrVoumes)
                allVolumes{vol,1} = sprintf('%s,%d',currentRun{1},vol);
            end
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
        
    end
    
    jobs{subj}.spm.stats.fmri_spec.dir = dirStats(subj);
    jobs{subj}.spm.stats.fmri_spec.timing.units = 'secs';
    jobs{subj}.spm.stats.fmri_spec.timing.RT = TR;
    jobs{subj}.spm.stats.fmri_spec.timing.fmri_t = 16;
    jobs{subj}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    
    
    
    jobs{subj}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    jobs{subj}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    jobs{subj}.spm.stats.fmri_spec.volt = 1;
    jobs{subj}.spm.stats.fmri_spec.global = 'None';
    jobs{subj}.spm.stats.fmri_spec.mthresh = 0.8;
    jobs{subj}.spm.stats.fmri_spec.mask = {''};
    jobs{subj}.spm.stats.fmri_spec.cvi = 'AR(1)';
    
    
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, [], par );


end % function
