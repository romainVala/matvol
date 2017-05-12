function  jobs = job_smooth(fi,par)
%old version
%function  jobs = job_write_norm(mat,fi,vox,interp,prefix,modulation)

if ~exist('par')
    par='';
end

defpar.smooth = [8 8 8];
defpar.prefix = 's';

defpar.sge = 0;
defpar.jobname='spm_smooth';
defpar.walltime = '00:30:00';

defpar.redo = 0;
defpar.run = 0;
defpar.display=0;


par = complet_struct(par,defpar);

for k=1:length(fi)
    jobs{k}.spm.spatial.smooth.data = cellstr(char(fi(k)));
    jobs{k}.spm.spatial.smooth.fwhm = par.smooth;
    jobs{k}.spm.spatial.smooth.dtype = 0;
    jobs{k}.spm.spatial.smooth.prefix = par.prefix;
end


if par.display
    spm_jobman('interactive',jobs);
    spm('show');
end

if par.run
    spm_jobman('run',jobs)
end


if par.sge
    clear jobs
    for k=1:length(fi)
        
        jobs{1}.spm.spatial.smooth.data = cellstr(char(fi(k)));
        
        j=jobs
        cmd = {'spm_jobman(''run'',j)'};
        varfile = do_cmd_matlab_sge(cmd,par);
        save(varfile{1},'j');
    end
end
