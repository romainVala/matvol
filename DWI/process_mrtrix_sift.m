function process_mrtrix_sift(sdata,trackin,par)
%function process_mrtrix_trackto(sdata,seed,par)

if ~exist('par')
    par='';
end

defpar.nthreads = 1;
defpar.sge = 1;
defpar.jobname = 'mrtrix_sift';
defpar.nthreads = 1;

par = complet_struct(par,defpar);

par.sge_nb_coeur = par.nthreads ;
cwd=pwd;
job={};

for nbsuj = 1:length(trackin)
    
    [dir_mrtrix, track_name, ex ] = fileparts(trackin{nbsuj});
    
        [dd, csd_name] = fileparts(sdata{nbsuj});

    
    cmd = sprintf('cd %s\n tcksift2 ',dir_mrtrix);
    
    if par.nthreads>1
        cmd = sprintf('%s -nthreads %d',cmd,par.nthreads);
    end
    
    cmd = sprintf('%s %s%s %s %s_weights.txt \n',cmd,track_name,ex,sdata{nbsuj},track_name);
    
    job{end+1} = cmd;
    
    
end%for nbsuj = 1:length(sdata)

do_cmd_sge(job,par)
