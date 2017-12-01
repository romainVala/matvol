function [job fmask] = do_fsl_bet(f,par,jobappend)

if ~exist('f'),f=get_subdir_regex_files;end 
if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end

defpar.frac = 0.1 ;
defpar.output_name = 'nodif_brain';
defpar.sge = 0;
defpar.software = 'fsl'; %to set the path
defpar.software_version = 5; % 4 or 5 : fsl version
defpar.jobname = 'bet2';
defpar.sge=0;
defpar.radius = [];
defpar.anat_brain=0;

par = complet_struct(par,defpar);


f=cellstr(char(f));

for k=1:length(f)
    
    [pp ff ] = fileparts(f{k});
    
    cmd = sprintf('cd %s;\n bet2 %s %s -m -f %f',pp,ff,par.output_name,par.frac);
	
    if par.anat_brain==0
	cmd = sprintf('%s -n ',cmd);
    end
    
    if ~isempty(par.radius)
        cmd = sprintf('%s -r %d',cmd,par.radius);
    end
    
    
    job{k} = cmd;
    
    fmask{k} = fullfile(pp,[par.output_name '_mask']);
end

job = do_cmd_sge(job,par,jobappend);
