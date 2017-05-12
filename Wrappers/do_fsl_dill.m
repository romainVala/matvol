function fo = do_fsl_dill(f,par)

if ~exist('par'),par ='';end

defpar.dill = 1;
defpar.name = 'dill_';

defpar.software = 'fsl'; %to set the path
defpar.software_version = 5; % 4 or 5 : fsl version
defpar.jobname = 'fsl_dill';
defpar.sge=0;
defpar.submit_sleep = 2;

par = complet_struct(par,defpar);



f=cellstr(char(f));

fo = addprefixtofilenames(f,par.name);

for k=1:length(f)
    [pp ff] = fileparts(f{k});
    
    if par.dill >0
        
        cmd = sprintf('fslmaths %s -dilM %s',f{k},fo{k});
        for kk=2:par.dill
            cmd = sprintf('%s\n fslmaths %s -dilM %s',cmd,fo{k},fo{k});
        end
        
    else
        cmd = sprintf('fslmaths %s -ero %s',f{k},fo{k});
        for kk=2:abs(par.dill)
            cmd = sprintf('%s\n fslmaths %s -ero %s',cmd,fo{k},fo{k});            
        end
        
    end
    
    job{k} = cmd;
end

do_cmd_sge(job,par)