function jobs = job_first_level_contrast(fspm,contrast,par)
% JOB_FIRST_LEVEL_CONTRAST - SPM:Stats:contrast manager
%
% par.sessrep = 
% 'none'   => do nothing fancy
% 'repl'   => replicate contrast over all sessions
% 'replsc' => replicate contrast over all sessions & scale (for comparaison with 2nd lvl analysis)
% 'sess'   => create contrast per session
% 'both'   => replicate & per session
% 'bosthsc'=> replicate & per session & scale


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.sessrep         = 'none'; 
defpar.file_reg        = '^s.*nii';

defpar.jobname         ='spm_glm';
defpar.walltime        = '04:00:00';

defpar.sge             = 0;
defpar.run             = 0;
defpar.display         = 0;
defpar.delete_previous = 0;
par.redo               = 0;

par = complet_struct(par,defpar);


%% SPM:Stats:contrast manager

for idx = 1:length(fspm)
    
    jobs{idx}.spm.stats.con.spmmat(1) = fspm(idx) ; %#ok<*AGROW>
    
    for nbc = 1:length(contrast.names)
        switch contrast.types{nbc}
            case 'T'
                jobs{idx}.spm.stats.con.consess{nbc}.tcon.name = contrast.names{nbc};
                jobs{idx}.spm.stats.con.consess{nbc}.tcon.weights = contrast.values{nbc};
                jobs{idx}.spm.stats.con.consess{nbc}.tcon.sessrep = par.sessrep;
                
            case 'F'
                jobs{idx}.spm.stats.con.consess{nbc}.fcon.name = contrast.names{nbc};
                jobs{idx}.spm.stats.con.consess{nbc}.fcon.weights = contrast.values{nbc};
                jobs{idx}.spm.stats.con.consess{nbc}.fcon.sessrep = par.sessrep;
                
        end
    end
    
    jobs{idx}.spm.stats.con.delete = par.delete_previous;
    
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, [], par );


end % function
