function jobs = job_first_level_estimate(fspm,par)


if ~exist('par')
    par='';
end


defpar.jobname='spm_glm_est';
defpar.walltime = '11:00:00';

defpar.sge = 0;
defpar.run = 0;
defpar.display=0;
par.redo=0;
par = complet_struct(par,defpar);


for nbs = 1:length(fspm)

    jobs{nbs}.spm.stats.fmri_est.spmmat = fspm(nbs) ;
    jobs{nbs}.spm.stats.fmri_est.write_residuals = 0;
    jobs{nbs}.spm.stats.fmri_est.method.Classical = 1;


end

if par.sge
    for k=1:length(jobs)
        j=jobs(k);
        cmd = {'spm_jobman(''run'',j)'};
        varfile = do_cmd_matlab_sge(cmd,par);
        save(varfile{1},'j');
    end
end

if par.display
    spm_jobman('interactive',jobs);
    spm('show');
end

if par.run
    spm_jobman('run',jobs)
end
