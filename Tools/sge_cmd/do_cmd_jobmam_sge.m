function do_cmd_jobmam_sge(job,par)


if ~exist('par'),  par=''; end

def_par.jobname='matlab_job';
def_par.software = '';%fsl freesurfer
def_par.software_version = '';
def_par.software_path = '';
def_par.job_append = 1;

def_par.jobdir=pwd;
def_par.sge_queu = 'matlab_nodes';
def_par.sge_nb_coeur=1;
def_par.submit_sleep = 1;  %add a sleep of 1 second between each qsub
def_par.fake = 0;
def_par.walltime = '02:00:00';
def_par.qsubappend = '';

par = complet_struct(par,def_par);


for k=1:length(job)
    j = job(k);
    var_file = do_cmd_matlab_sge({'spm_jobman(''run'',j)'},par);
    save(var_file{1},'j');
end
