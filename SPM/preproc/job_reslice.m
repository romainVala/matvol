function  jobs = job_reslice(fmove,fref,par)

if ~exist('par')
    par='';
end
defpar.prefix = 'r';
defpar.interp=4;
defpar.sge = 0;
defpar.run = 0;
defpar.display=0;
defpar.jobname='spm_reslice';
defpar.walltime = '01:00:00';

par = complet_struct(par,defpar);


for k=1:length(fref)
    
    ffsession = cellstr(fmove{k}) ;
        
    if length(ffsession) == 1 %4D file
        clear ffs
        V = spm_vol(ffsession{1});
        for kk=1:length(V)
            ffs{kk} = sprintf('%s,%d',ffsession{1},kk);
        end
    else
        ffs = ffsession;
    end

    %-----------------------------------------------------------------------
    % Job configuration created by cfg_util (rev $Rev: 2787 $)
    %-----------------------------------------------------------------------
    jobs{k}.spm.spatial.coreg.write.ref = fref(k);
    
    jobs{k}.spm.spatial.coreg.write.source = ffs';
    
    jobs{k}.spm.spatial.coreg.write.roptions.interp = par.interp;
    jobs{k}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
    jobs{k}.spm.spatial.coreg.write.roptions.mask = 0;
    jobs{k}.spm.spatial.coreg.write.roptions.prefix = par.prefix;
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

