function varargout = do_cmd_matlab_sge(job,par,jobappend,qsubappend)


if ~exist('par'),  par=''; end
if ~exist('jobappend','var'), jobappend ='';end
if ~exist('qsubappend','var'), qsubappend ='';end

def_par.jobname='jobname';
def_par.job_append = 1;
def_par.matlab_opt = '-singleCompThread -nodesktop  -nosoftwareopengl';
%def_par.matlab_opt = '-singleCompThread -nodesktop -nojvm -nosoftwareopengl';
def_par.get_matlab_path = 1;

def_par.jobdir=pwd; 
%def_par.sge_queu = 'matlab_nodes';
def_par.sge_queu = 'normal';
def_par.sge_nb_coeur=1;
def_par.submit_sleep = 1;  %add a sleep of 1 second between each qsub
def_par.fake = 0;
def_par.walltime = '';
def_par.qsubappend = '';
def_par.job_pack=1;

par = complet_struct(par,def_par);

if ~isempty(jobappend)
    for kk=1:length(job)
        job{kk} = sprintf('%s\n\n%s',jobappend{kk},job{kk});
    end
end

job_dir = fullfile(par.jobdir,par.jobname);

if ~exist(job_dir)
    mkdir(job_dir);
end

if par.job_append
    %dd=dir([job_dir '/*' par.jobname '*']);
    dd=get_subdir_regex_files(job_dir,['^j.*' par.jobname],struct('verbose',0));if ~isempty(dd),dd = cellstr(char(dd));end
    kinit = length(dd);
else
    kinit = 0;
end

%find matlab exec
bb= which('null');
[pp ff]=fileparts(bb); [pp ff]=fileparts(pp); [pp ff]=fileparts(pp); [pp ff]=fileparts(pp);
matdir = fullfile(pp,'bin','matlab');

if par.job_pack>1;
    jnew={};
    for nn=1:par.job_pack:length(job)
        kkkend = nn+par.job_pack-1;
        if kkkend>length(job)
            kkkend=length(job);
        end
        aa = job{nn};
        for kkk=nn+1:kkkend
            aa = [aa, job{kkk}];
        end
        jnew(end+1)={aa};
    end
    job=jnew;
    par.job_pack=1;
end

for k=1:length(job)
    
    jname = sprintf('j%.2d_%s',k+kinit,par.jobname);
    
    fpn = fullfile(job_dir,jname);
    job_variable{k} = fullfile(job_dir,['variable_' jname '.mat']);
    job_fonc{k} = fullfile(job_dir,['mfonc_' jname]);
    
    fpnfonc = fopen([job_fonc{k} '.m'],'w');
    if par.get_matlab_path
        llp = path;
        fprintf(fpnfonc,' path(''%s'');\n',llp);
    end

    if nargout>=1
        fprintf(fpnfonc,'\nload %s;\n\n',job_variable{k});
    end
    
    jjj=job{k};
    
fprintf(fpnfonc,'\n\ntry\n\n ');
if iscell(jjj)
fprintf(fpnfonc,'%s \n',jjj{:});
else
fprintf(fpnfonc,'%s ',jjj);
end

fprintf(fpnfonc,'\n\n catch err\n display(err.message);\n disp(getReport(err,''extended''));\n\n end\n quit force \n ');
    
    fclose(fpnfonc);        
    
%    cmdd{k} = sprintf('\nexport LANG=fr_FR.UTF-8\n\n %s %s -r "run(''%s'')"\n',matdir,par.matlab_opt,job_fonc{k});
     cmdd{k} = sprintf('\n %s %s -r "run(''%s'')"\n',matdir,par.matlab_opt,job_fonc{k});
    
    
end

[job f_do_qsubar] = do_cmd_sge(cmdd,par,'',qsubappend);

if nargout>=1
    varargout{1} = job_variable;
    varargout{2} = f_do_qsubar; 
end

