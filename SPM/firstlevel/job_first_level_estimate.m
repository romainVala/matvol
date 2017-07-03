function jobs = job_first_level_estimate(fspm,par)
% JOB_FIRST_LEVEL_ESTIMATE - SPM:Stats:model estimation

%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.jobname  = 'spm_glm_est';
defpar.walltime = '11:00:00';

defpar.sge      = 0;
defpar.run      = 0;
defpar.display  = 0;
defpar.redo     = 0;

par = complet_struct(par,defpar);


%% SPM:Stats:model estimation

for idx = 1:length(fspm)

    jobs{idx}.spm.stats.fmri_est.spmmat = fspm(idx) ; %#ok<*AGROW>
    jobs{idx}.spm.stats.fmri_est.write_residuals = 0;
    jobs{idx}.spm.stats.fmri_est.method.Classical = 1;


end

%% Other routines

[ jobs ] = job_ending_rountines( jobs, [], par );


end % function
