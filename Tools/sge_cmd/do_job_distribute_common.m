
mp = mfilename('fullpath');

start_date = datestr(now,31);

nb_er=0;

for k=1 : length(job)
  tic;
  lls{k} = datestr(now,31);
  
  fprintf('\n%s : Starting job %s\n ',datestr(now,31),job{k})
  
  try
     spm_jobman('run',job{k});
    
  catch
     nb_er=nb_er+1;
     fprintf('Ail eror in runing the job %s \n',job{k});
     % fprintf('SPM error %s',lasterror);
     lasterror;
   end
   llt(k)=toc;
end

ttime=sum(llt);

fprintf('\nstarted the %s\n',start_date);

fprintf('\nDone the %s\n',datestr(now,31));

fprintf('\n\n %d job done with %d error\n',length(job),nb_er);

fprintf('total time %d s (%f H)\n',ttime,(ttime/60/60));

for k=1:length(job)
  fprintf('\t job %d : %s \n',k,job{k})
  fprintf('\t performed in %d s (%f H)\n',llt(k),(llt(k)/60/60));
end

exit
