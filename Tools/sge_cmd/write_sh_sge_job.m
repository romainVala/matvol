function write_sh_sge_job(type,rootjob,param)

if ~isfield(param,'queu')
  param.queu = 'server_ondule';
end

p.verbose=0;
ff = get_subdir_regex_files(rootjob,type,p);
if isempty(ff)
  numjob=1;
else
  numjob=size(ff{1},1)+1;
end

jname = fullfile(rootjob,sprintf('%s_job_%.3d',type,numjob) ); 
jname_err = [jname '_err.log'];
jname_log = [jname '_log.log'];
        
fj = fopen(jname,'w+');

if ~isempty(findstr(type,'eddycor')) || ~isempty(findstr(type,'fslunwrap'))
   
    fprintf(fj,'#$ -S /bin/bash \n source /usr/cenir/bincenir/fsl_path2; \n  ');
    [datapath invol ext] = fileparts(param.invol);
    invol = [invol ext];
    fprintf(fj,'cd %s\n',datapath);
     
end    

switch type
  case 'eddycor'
    fprintf(fj,'eddy_correct %s %s 0 \n',invol,param.outvol);
    
  case 'fslunwrap'
    mag = param.inmag;
    phase = param.inphase;
    
    fprintf(fj,'/usr/cenir/bincenir/epidewarp.rrr.fsl --mag %s --dph %s --epi %s --tediff %f --esp %f --vsm voxel_shift_map --epidw %s \n',...
      mag,phase,invol,param.tediff,param.esp,param.outvol);
    
  case 'fslunwrap_dtifit'

    mag = param.inmag;
    phase = param.inphase;
    
    fprintf(fj,'/usr/cenir/bincenir/epidewarp.rrr.fsl --mag %s --dph %s --epi %s --tediff %f --esp %f --vsm voxel_shift_map --epidw %s \n',...
      mag,phase,invol,param.tediff,param.esp,param.outvol);
  
    fprintf(fj,'dtifit -k %s -o %s -m %s -r bvecs -b bvals\n',param.invol_dtifit,param.sujid,param.mask);
    
end

fclose(fj);


fprintf('writing job %s\n',jname);


qsubname = fullfile(rootjob,'do_qsub.sh');

if ~exist(qsubname)
  fqsub = fopen(qsubname,'w+');
  fprintf(fqsub,'source /usr/cenir/sge/default/common/settings.sh \n');

else
  fqsub = fopen(qsubname,'a+');
end

fprintf(fqsub,'qsub -q %s -o %s -e %s %s\n',param.queu,jname_log,jname_err,jname);

fclose(fqsub);

unix(['chmod +x  ' qsubname]);
