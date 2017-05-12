function job = do_cmd_sge(job,par,jobappend)


if ~exist('par'),  par=''; end
if ~exist('jobappend','var'), jobappend ='';end

def_par.jobname='jobname';
def_par.software = '';%fsl freesurfer
def_par.software_version = '';
def_par.software_path = '';

def_par.jobdir=pwd;
def_par.sge=1;
def_par.sge_queu = 'ICM';
def_par.job_append = 1;
def_par.sge_nb_coeur=1;
def_par.submit_sleep = 1;  %add a sleep of 1 second between each qsub
def_par.fake = 0;
def_par.walltime = '';
def_par.qsubappend = '';
def_par.mem = '';

par = complet_struct(par,def_par);

if ~isempty(jobappend)
    for kk=1:length(job)
        job{kk} = sprintf('%s\n\n%s',jobappend{kk},job{kk});
    end
end

if par.sge == -1
    return
end

%make jobdir in a subdir with jobname
par.jobdir = fullfile(par.jobdir,par.jobname);

if par.sge==0
    for nn=1:length(job)
        cmd = job{nn};
        if nn<3 || nn>(length(job)-3)
            fprintf('runing %s \n\n',cmd);
        end
        if par.fake,    else    unix(cmd);        end
    end
    
else
    
    job_dir = par.jobdir;
    
    if ~exist(job_dir)
        mkdir(job_dir);
    end
    
    
    % unix('source /usr/cenir/sge/default/common/settings.sh ')
    
    fprintf('\n writing %d job for the grid engin in %s \n',length(job),job_dir);
    
    f_do_qsub=fullfile(job_dir,'do_qsub_sge.sh');
    f_do_qsubar=fullfile(job_dir,'do_qsub.sh');
    f_do_array=fullfile(job_dir,'do_job_array.sh');
    f_do_loc=fullfile(job_dir,'do_all_local.sh');
    
    if par.job_append
        fqsub=fopen(f_do_qsub,'a');
        fqsubar=fopen(f_do_qsubar,'w');
        floc=fopen(f_do_loc,'a');
    else
        fqsub=fopen(f_do_qsub,'w');
        fqsubar=fopen(f_do_qsubar,'w');
        floc=fopen(f_do_loc,'w');
    end
    
    if par.job_append
        %dd=dir([job_dir '/*' par.jobname '*']);
        dd=get_subdir_regex_files(job_dir,['^j.*' par.jobname],struct('verbose',0));if ~isempty(dd),dd = cellstr(char(dd));end
        kinit = length(dd);
    else
        kinit = 0;
    end
    
    for k=1:length(job)
        
        cmdd = job{k};
        
        % it is not usefule if already well define in your .bashrc in case you need
        if ~isempty(par.software_path)
            cmdd = sprintf('%s\n%s',par.software_path,cmdd);
        end
        
        jname = sprintf('j%.2d_%s',k+kinit,par.jobname);
          
        fpn = fullfile(job_dir,jname);
        fpnlog = sprintf('%s.log',fpn);
        fpnlogerror = sprintf('%s.err',fpn);
        
        ff=fopen(fpn,'w');
        switch par.sge_queu
            case {'server_ondule','server_irm'}
                fprintf(ff,'#$ -S /bin/bash \n');
                fprintf(ff,cmdd);
                fclose(ff);
                
            case {'small','medium','long','lena','workq','matlab','matlab_nodes','ICM'}
                fprintf(ff,'#!/bin/bash\n#\n#PBS -N %s\n',jname);
                fprintf(ff,'#\n#PBS -q %s\n',par.sge_queu);
                if strcmp(par.sge_queu,'lena')
                    fprintf(ff,'#\n#PBS -l nodes=1:ppn=%d:lena',par.sge_nb_coeur);
                elseif strcmp(par.sge_queu,'matlab')
                    fprintf(ff,'#\n#PBS -l nodes=1:ppn=%d:hpc_matlab',par.sge_nb_coeur);
               else
                    fprintf(ff,'#\n#PBS -l nodes=1:ppn=%d:hpc',par.sge_nb_coeur);
                end
                if ~isempty(par.walltime')
                    fprintf(ff,'\n#PBS -l walltime=%s',par.walltime);
                end
         
                fprintf(ff,'\n\necho started on $HOSTNAME \n date\n\n');
                fprintf(ff,'tic="$(date +%%s)"\n');
                
                %fprintf(ff,'',);
                fprintf(ff,cmdd);
                
                fprintf(ff,'\n\ntoc="$(date +%%s)";\nsec="$(expr $toc - $tic)";\nmin="$(expr $sec / 60)";\nheu="$(expr $sec / 3600)";\necho Elapsed time: $min min $heu H\n');
                fclose(ff);
            otherwise
                error('queue %s is unknown',par.sge_queu)
        end
        
        cmd{k} = sprintf('qsub -V -q %s %s -o %s -e %s %s',par.sge_queu,par.qsubappend,fpnlog,fpnlogerror,fpn);
        fprintf(fqsub,'%s\n sleep %d \n',cmd{k},par.submit_sleep);
        
        fprintf(floc,'sh %s\n',fpn);
        
    end
    
    fclose(fqsub);fclose(floc);
    
    
    fprintf(fqsubar,'qsub -q %s -l nodes=1:ppn=%d -N %s %s ',par.sge_queu,par.sge_nb_coeur,par.jobname,par.qsubappend);
    if ~isempty(par.walltime)
        fprintf(fqsubar,' -l walltime=%s',par.walltime);
    end  
    if ~isempty(par.mem)
        fprintf(fqsubar,' -l mem=%s',par.mem);
    end
    
    fprintf(fqsubar,' -o %s -e %s -t 1-%d %s\n',job_dir,job_dir,k+kinit,f_do_array);
    fclose(fqsubar);
    
    fffa = fopen(f_do_array,'w');
    fprintf(fffa,'#!/bin/sh \n cmd=$( printf "j%%02d_%s" ${PBS_ARRAYID})\n sh %s/$cmd\n',par.jobname,job_dir);
    fclose(fffa);
    
    cmdout=sprintf('sh %s',f_do_qsub);
    
    if strfind(par.jobname,'dti_bedpostx')
        fprintf('\n warning RUN without qsub because bedpostx calls qsub\n');
        cmdout=sprintf('sh %s',f_do_loc);
        delete(f_do_qsub)
    end
end
