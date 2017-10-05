function [job fout] = do_fsl_dtieddycor(f4D,par,jobappend)

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end

defpar.suffix='_eddycor';
%
defpar.software = 'fsl'; %to set the path
defpar.software_version = 5; % 4 or 5 : fsl version
defpar.jobname = 'dti_eddycor';
defpar.refnumber = 0;
%see also default params from do_cmd_sge
par = complet_struct(par,defpar);



for nbs=1:length(f4D)
    [pp ff ] = fileparts(f4D{nbs});
    ff=change_file_extension(ff,'');
    cmd =sprintf('cd %s;eddy_correct %s %s%s %d \n',pp,ff,ff,par.suffix,par.refnumber);
    
    job{nbs} = cmd;
    
    fout{nbs} = fullfile(pp,[ff par.suffix]);
end


job = do_cmd_sge(job,par,jobappend);
