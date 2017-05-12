function job = redo_cmd_matlab(jobdir,jobname)

if ischar(jobdir)
    jobdir={jobdir};
end

mfonc = get_subdir_regex_files(jobdir,'m$');

nbjob = size(mfonc{1},1);


qsubf = fullfile(jobdir{1},'do_qsub.sh')
ff=fopen(qsubf)

qcmd = fgetl(ff)

fclose(ff)

ind=strfind(qcmd,'-t');

qq1=qcmd(1 : ind-1);
qq2=qcmd(ind:end);

inds = strfind(qq2,' ')

qq2(1:inds(2)) = '';

cmdclean = [qq1 qq2];


if ~exist('jobname')
    ind=strfind(qcmd,'-N');
    aa = qcmd(ind:end);
    inds = strfind(aa,' ');
    jobname = aa(inds(1)+1:inds(2)-1);
end

strjob='';
for k=1:nbjob
    %logna = sprintf('%s.o.*-%d$',jobname,k);
    %logf = get_subdir_regex_files(jobdir,logna);
    
    logna = sprintf('%s/%s.o*-%d',jobdir{1},jobname,k);
    if isempty(dir(logna))
        strjob=sprintf('%s,%d',strjob,k);
    end
end
if isempty(strjob)
    fprintf('it seems OK\n')
    return
end

strjob(1)='';

cmd = sprintf('%s -t %s',cmdclean,strjob);

qsubf = fullfile(jobdir{1},'do_qsub_again.sh');
ff=fopen(qsubf,'w+');
fprintf(ff,'%s',cmd);
fclose(ff);

