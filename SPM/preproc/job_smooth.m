function  jobs = job_smooth(fi,par)
% JOB_SMOOTH - SPM:Spatial:Smooth
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also get_subdir_regex get_subdir_regex_files


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.smooth   = [8 8 8];
defpar.prefix   = 's';

defpar.sge      = 0;
defpar.jobname  = 'spm_smooth';
defpar.walltime = '00:30:00';

defpar.redo     = 0;
defpar.run      = 0;
defpar.display  = 0;

par = complet_struct(par,defpar);


%% SPM:Spatial:Smooth
for k=1:length(fi)
    jobs{k}.spm.spatial.smooth.data = cellstr(char(fi(k))); %#ok<*AGROW>
    jobs{k}.spm.spatial.smooth.fwhm = par.smooth;
    jobs{k}.spm.spatial.smooth.dtype = 0;
    jobs{k}.spm.spatial.smooth.prefix = par.prefix;
end


%% Other routines

if isempty(jobs)
    return
end


if par.sge
    for vol=1:length(jobs)
        j       = jobs(vol); %#ok<NASGU>
        cmd     = {'spm_jobman(''run'',j)'};
        varfile = do_cmd_matlab_sge(cmd,par);
        save(varfile{1},'j');
    end
end


if par.display
    spm_jobman('interactive',jobs);
    spm('show');
end


% Run !
if par.run
    spm_jobman('run',jobs)
end

end % function
