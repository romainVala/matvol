function do_job_distribute(job,p)

mpath =  fileparts(which('go'));
spath = fileparts(which('spm'));

job_dir = p.rootdir;
if ~isfield(p,'distrib')
  p.distrib.arg=1;
end
  
if ~isfield(p.distrib,'subdir')
  p.distrib.subdir='distrib_bash';
end

job_dir = fullfile(p.rootdir,p.distrib.subdir);
if ~exist(job_dir)
  mkdir(job_dir);
end
  


unix('source /usr/cenir/sge/default/common/settings.sh ')

fprintf('\n running %d job on the sun grid engin \n',length(job));
q=input('do you want to check before ? y \n ','s');


for k=1:length(job)
  
  fcmd = sprintf('to_be_execute_%d_the_%s',k,datestr(now,30));

  ffcmd = fullfile(job_dir,[fcmd,'.m']);

  ffjob = fullfile(job_dir,['matlab_job_' p.do_preproc{1} '_' num2str(k) '.sh']);

  fpnlog = fullfile(job_dir,sprintf('log_matlab_job%d.log',k));
  fpnlogerror = fullfile(job_dir,sprintf('log_err_matlab_job%d.log',k));

  cmdd = sprintf('#$ -S /bin/bash \n echo run on `hostname` \n');

%  cmdd = sprintf('%s cd %s;\n matlab -nodesktop -logfile_matlab_output.log -r ''%s'' ;\n',cmdd,job_dir,fcmd,fcmd);
  cmdd = sprintf('%s cd %s;\n matlab -nodesktop -r ''%s'' ;\n',cmdd,job_dir,fcmd);
 
  fijob = fopen(ffjob,'w');
  fprintf(fijob,'%s',cmdd);
  fclose(fijob);
  
  fip=fopen(ffcmd,'w');

  fprintf(fip,'addpath(''%s'')\n',mpath);
  fprintf(fip,'addpath(''%s'')\n',spath);
  fprintf(fip,'go\n');


  fprintf(fip,'job{1} = ''%s'';\n ',job{k});


  fprintf(fip,'do_job_distribute_common \n');
  
  fclose(fip);
  
  cmd{k} = sprintf('qsub -q matlab -o %s -e %s %s', fpnlog,fpnlogerror,ffjob);

  if strcmp(q,'y')

    fprintf(' %s is \n  %s \n',ffjob,cmdd)
    fprintf('%s\n',cmd{k})
  
  else
    
    unix(cmd{k})
    pause(1)

  end

end



if strcmp(q,'y')
  qq = input('do you want to run it now ? y \n','s');
  if strcmp(qq,'y')
    for k=1:length(job)
      unix(cmd{k})
      pause(1)
    end
  end
end

