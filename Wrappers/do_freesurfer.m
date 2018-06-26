function [jobs do]= do_freesurfer(anat,params)

def_par.walltime = '23:00:00';
def_par.sge_queu = 'normal';
def_par.skip = 1;
def_par.version = 5;
def_par.version_path='module load FreeSurfer/6.0.0';
def_par.free_cmd='freesurfer';
def_par.free_sujdir='';
def_par.add_sername_to_sujname=0;
def_par.jobname = 'freesurfer_reconall';
def_par.cmd_append='';

params = complet_struct(params,def_par);


if isempty(params.free_sujdir)
    [pr ff] = get_parent_path(anat,3);
    aa = r_mkdir(pr(1),'freesurfer');
    params.free_sujdir = aa{1};
    char(params.free_sujdir);
end
    
    
jobs = {};

for nbsuj=1:length(anat)
    
    
    [panat fff] = get_parent_path(anat(nbsuj));
    filename = cellstr(char(anat(nbsuj)));
    
    [psuj sername] = fileparts(panat{1});
    
    if isfield(params,'sujname')
        sujname = params.sujname{nbsuj};
    else
        [proot,sujname] = fileparts(psuj);
        if params.add_sername_to_sujname
            sujname = [sujname '_' sername];
        end
        %remove space
        sujname = nettoie_dir(sujname);

    end
    
        
    
    if iscell(params.free_sujdir)
        freesujdir = params.free_sujdir{nbsuj};
    else
        freesujdir = params.free_sujdir;
    end
    
    if ~strcmp(freesujdir(1),'/')
        freesujdir = fullfile(psuj,freesujdir);
    end
    
    if ~exist(freesujdir)
        mkdir (freesujdir)
    end
    
    
    if findstr(psuj,' ')
        ind=findstr(psuj,' ');
        if length(ind)>1
            fprinft('do not use space in subject names')
            keyboard
        else
            psuj = [psuj(1:ind-1) '\\ ' psuj(ind+1:end)];
        end
        
    end
    
    
    sujfree_dir = fullfile(freesujdir,sujname);
    do{nbsuj} = sujfree_dir;
    
    if exist(sujfree_dir) & params.skip
        
        fprintf('Skiping suj %s because freesurfer dir exist :%s \n',sujname,freesujdir)
        %   jobs{nbjobs}.free_cmd = '';
        
    else
        cmd = sprintf('recon-all ');

        if strfind(params.free_cmd,'again')
            cmd = sprintf('%s -s %s -sd %s  ',cmd,sujname,freesujdir);
        else
            
            for nbf=1:length(filename)
                cmd = sprintf('%s -i %s',cmd,filename{nbf});
            end
            
            switch params.free_cmd
                case 'freesurferall'
                    cmd = sprintf('%s -s %s -sd %s -all -qcache ',cmd,sujname,freesujdir);
                    
                case 'freesurfer'
                    cmd = sprintf('%s -s %s -sd %s -all ',cmd,sujname ,freesujdir);
                    
                case 'freesurferhippo'
                    cmd = sprintf('%s -s %s -sd %s -all -hippo-subfields',cmd,sujname ,freesujdir);
                    
                case 'freesurfercrop'
                    cmd = sprintf('%s -s %s -cw256 -sd %s -all ',cmd,sujname ,freesujdir);
                    
                    
                case 'freesurfer_qcache'
                    cmd = sprintf('recon-all  -s %s -sd %s -qcache ',sujname ,freesujdir);
                    
            end
        end
        
        cmd = sprintf('%s %s ',cmd,params.cmd_append);
        
        %cmd = sprintf('cd %s\n%s',psuj,cmd);
        
        if ~isempty(params.version_path)
            cmd = sprintf('%s \n%s\n',params.version_path,cmd);
        else
            
            if params.version == 5
                [a b]=unix('which freesurfer5.3') ;
                cmd = sprintf('source %s \n %s \n',b,cmd);
            else
                cmd = sprintf('source /usr/cenir/bincenir/freesurfer; \n %s \n',cmd);
            end
        end
        jobs{end+1} = cmd;
        
    end
    
end


if ~isempty(jobs)
    %if isempty(job_dir), params.job_dir = proot; end
    do_cmd_sge(jobs,params);
    
end
