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

[ jobs ] = job_ending_rountines( jobs, [], par );


end % function
