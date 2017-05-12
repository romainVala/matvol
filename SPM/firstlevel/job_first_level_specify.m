function jobs = job_first_level_specify(dfonc,stat_dir,onset_mat,par)


if ~exist('par')
    par='';
end


defpar.file_reg = '^s.*nii';
defpar.rp = 0;

defpar.jobname='spm_glm';
defpar.walltime = '04:00:00';

defpar.sge = 0;
defpar.run = 0;
defpar.display=0;

par.redo=0;
par = complet_struct(par,defpar);

TR = par.TR;

if iscell(dfonc{1}),    nsuj = length(dfonc); else,    nsuj=1; end

for nbs = 1:nsuj
    
    if iscell(dfonc{1}) %
        ff = get_subdir_regex_files(dfonc{nbs},par.file_reg);
        unzip_volume(ff);
        ff = get_subdir_regex_files(dfonc{nbs},par.file_reg);
        if par.rp
            frp = get_subdir_regex_files(dfonc{nbs},'^rp.*txt');
        end
    else
        ff = dfonc;
        
    end
    
    if ~ isstruct(onset_mat{1})
        fonset = cellstr(char(onset_mat(nbs)));
    end
    
    for nsess=1:length(ff)
        ffsession = cellstr(ff{nsess}) ;
        clear ffs
        
        if length(ffsession) == 1 %4D file
            V = spm_vol(ffsession{1});
            for k=1:length(V)
                ffs{k,1} = sprintf('%s,%d',ffsession{1},k);
            end
        else
            ffs = ffsession;
        end
        jobs{nbs}.spm.stats.fmri_spec.sess(nsess).scans = ffs;
        jobs{nbs}.spm.stats.fmri_spec.sess(nsess).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        jobs{nbs}.spm.stats.fmri_spec.sess(nsess).multi = {''};
        if isstruct(onset_mat{1})
            jobs{nbs}.spm.stats.fmri_spec.sess(nsess).cond = onset_mat{nsess};
        else
            jobs{nbs}.spm.stats.fmri_spec.sess(nsess).multi = fonset(nsess);
        end
        
        if par.rp
            jobs{nbs}.spm.stats.fmri_spec.sess(nsess).multi_reg = frp(nsess);
        else
            jobs{nbs}.spm.stats.fmri_spec.sess(nsess).multi_reg = {''};
        end
        %matlabbatch{1}.spm.stats.fmri_spec.sess(4).multi_reg = {'/servernas/home/home_ubu14/romain/pres_romain.txt'};

        jobs{nbs}.spm.stats.fmri_spec.sess(nsess).regress = struct('name', {}, 'val', {});
        jobs{nbs}.spm.stats.fmri_spec.sess(nsess).hpf = 128;
        
    end
    
    jobs{nbs}.spm.stats.fmri_spec.dir = stat_dir(nbs);
    jobs{nbs}.spm.stats.fmri_spec.timing.units = 'secs';
    jobs{nbs}.spm.stats.fmri_spec.timing.RT = TR;
    jobs{nbs}.spm.stats.fmri_spec.timing.fmri_t = 16;
    jobs{nbs}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    

    
    jobs{nbs}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    jobs{nbs}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    jobs{nbs}.spm.stats.fmri_spec.volt = 1;
    jobs{nbs}.spm.stats.fmri_spec.global = 'None';
    jobs{nbs}.spm.stats.fmri_spec.mthresh = 0.8;
    jobs{nbs}.spm.stats.fmri_spec.mask = {''};
    jobs{nbs}.spm.stats.fmri_spec.cvi = 'AR(1)';
    
    
    % jobs{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    % jobs{2}.spm.stats.fmri_est.write_residuals = 0;
    % jobs{2}.spm.stats.fmri_est.method.Classical = 1;
    
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
