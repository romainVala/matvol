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

skip = [];

for idx = 1:length(fspm)
    
    beta_file = fullfile(fileparts(fspm{idx}),'beta_0001.nii');
    if ~par.redo   &&  exist(beta_file,'file')
        skip = [skip idx];
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,idx,beta_file);
    end
    
    jobs{idx}.spm.stats.fmri_est.spmmat = fspm(idx) ; %#ok<*AGROW>
    jobs{idx}.spm.stats.fmri_est.write_residuals = 0;
    jobs{idx}.spm.stats.fmri_est.method.Classical = 1;
    
end

%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


end % function
