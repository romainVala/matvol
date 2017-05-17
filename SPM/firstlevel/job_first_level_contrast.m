function jobs = job_first_level_contrast(fspm,contrast,par)


if ~exist('par')
    par='';
end

defpar.sessrep = 'none'; % 'none', 'repl' => replicate contrast over all sessions
defpar.TR   = 0;
defpar.file_reg = '^s.*nii';

defpar.jobname='spm_glm';
defpar.walltime = '04:00:00';

defpar.sge = 0;
defpar.run = 0;
defpar.display=0;
defpar.delete_previous = 0;

par.redo=0;
par = complet_struct(par,defpar);


for nbs = 1:length(fspm)
    
    jobs{nbs}.spm.stats.con.spmmat(1) = fspm(nbs) ;
    
    for nbc = 1:length(contrast.names)
        switch contrast.types{nbc}
            case 'T'
                jobs{nbs}.spm.stats.con.consess{nbc}.tcon.name = contrast.names{nbc};
                jobs{nbs}.spm.stats.con.consess{nbc}.tcon.weights = contrast.values{nbc};
                jobs{nbs}.spm.stats.con.consess{nbc}.tcon.sessrep = par.sessrep;
            case 'F'
                
                jobs{nbs}.spm.stats.con.consess{nbc}.fcon.name = contrast.names{nbc};
                jobs{nbs}.spm.stats.con.consess{nbc}.fcon.weights = contrast.values{nbc};
                jobs{nbs}.spm.stats.con.consess{nbc}.fcon.sessrep = par.sessrep;
                
        end
    end
    
    jobs{nbs}.spm.stats.con.delete = par.delete_previous;
    
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
