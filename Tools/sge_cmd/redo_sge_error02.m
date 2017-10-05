function job = redo_sge_error(jobdir,error_msg,grep_error)

if ~exist('grep_error','var')
    grep_error = 1; %if ==0 then it will look into log file
end

if ~exist('error_msg','var')
    error_msg='illed';
end

if ischar(jobdir)
    jobdir={jobdir};
end
[pp jobname] = get_parent_path(jobdir);


qsubf = fullfile(jobdir{1},'do_qsub.sh');
ff=fopen(qsubf);

qcmd = fgetl(ff);

fclose(ff);

%for sge ind=strfind(qcmd,'-t');
ind=strfind(qcmd,'--array');

qq1=qcmd(1 : ind-1);
qq2=qcmd(ind:end);

inds = strfind(qq2,' ');

qq2(1:inds(1)) = '';

cmdclean1 = qq1;
cmdclean2 = qq2 ;

%erf = get_subdir_regex_files(jobdir,[jobname{1} '.e']);
erf = get_subdir_regex_files(jobdir,'err');
erf = cellstr(char(erf));
logf =  get_subdir_regex_files(jobdir,'log');logf = cellstr(char(logf));


strjob='';

redodir = r_mkdir(jobdir,'redo');

for k=1:length(erf)
    if grep_error,    thefile=erf{k};
    else thefile = logf{k}; end
    
    s=dir(thefile );
    if s.bytes % only non empty files
        if grep_error
            cmd = sprintf('cat %s |grep "%s"',thefile,error_msg);
        else
            cmd = sprintf('cat %s |grep "%s"',thefile,error_msg);
        end
        
        [a b] = unix(cmd);
        if ~isempty(b)
            %find job_number
            [pp, efile] = fileparts(erf{k});
            ii = strfind(efile,'_');
            numjob = str2num(efile(ii+1:end));
            
            
            %strjob=sprintf('%s,%d',strjob,k);
            strjob=sprintf('%s,%d',strjob,numjob);
            r_movefile(erf(k),redodir{1},'move');
            r_movefile(logf(k),redodir{1},'move');
        else
            if grep_error
            fprintf(' Error file %s not empty but not error message %s\n',erf{k},error_msg);
            end
        end
    end
end

strjob(1)='';

%cmd = sprintf('%s -t %s',cmdclean,strjob);
cmd = sprintf('%s --array=%s %s\n',cmdclean1 ,strjob,cmdclean2);

qsubf = fullfile(jobdir{1},'do_qsub_again.sh');
ff=fopen(qsubf,'w+');
fprintf(ff,'%s',cmd);
fclose(ff);


if 0 %delete freesurfer sujdir
a=str2num(strjob)
for k=1:length(a)
jname=sprintf('j%.2d_freesurfer_reconall',a(k))
l=readtext(jname);
aa=split(l{3})
cmd{k} = sprintf('rm -rf %s/%s',aa{7},aa{5})
par.sge=0;         
do_cmd_sge(cmd,par)

end
end

