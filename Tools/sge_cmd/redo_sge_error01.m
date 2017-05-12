function job = redo_sge_error(jobdir,error_msg,grep_error)

if ~exist('grep_error','var')
    grep_error = 1; %if ==0 then it will look into log file
end

if ~exist('error_msg','var')
    error_msg='Killed';
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

qq2(1:inds(2)) = '';

cmdclean1 = qq1;
cmdclean2 = qq2 ;

%erf = get_subdir_regex_files(jobdir,[jobname{1} '.e']);
erf = get_subdir_regex_files(jobdir,'err-');
erf = cellstr(char(erf));
logf =  get_subdir_regex_files(jobdir,'log');logf = cellstr(char(logf));


strjob='';

redodir = r_mkdir(jobdir,'redo/');

for k=1:length(erf)
    %error_file_in_order = get_subdir_regex_files(jobdir,[jobname{1} '.e.*-' num2str(k) '$']);
    
    %     jname = sprintf('j%.2d_%s.err',k,jobname{1});
    %     error_file_in_order = get_subdir_regex_files(jobdir,jname);
    
    %     if isempty(error_file_in_order)
    %         strjob=sprintf('%s,%d',strjob,k);
    %     else
    %cmd = sprintf('cat %s |grep %s',error_file_in_order{1},error_msg);
    if grep_error
        cmd = sprintf('cat %s |grep "%s"',erf{k},error_msg);
    else
        cmd = sprintf('cat %s |grep "%s"',logf{k},error_msg);
    end
    
    [a b] = unix(cmd);
    if ~isempty(b)
        %find job_number
        [pp, efile] = fileparts(erf{k});
        ii = strfind(efile,'_')
        numjob = str2num(efile(ii+1:end))
        
        
        %strjob=sprintf('%s,%d',strjob,k);
        strjob=sprintf('%s,%d',strjob,numjob);
        r_movefile(erf(k),redodir{1},'move');
        r_movefile(logf(k),redodir{1},'move');
        
    end
    %     end
end

strjob(1)='';

%cmd = sprintf('%s -t %s',cmdclean,strjob);
cmd = sprintf('%s --array %s %s\n',cmdclean1 ,strjob,cmdclean2);

qsubf = fullfile(jobdir{1},'do_qsub_again.sh');
ff=fopen(qsubf,'w+');
fprintf(ff,'%s',cmd);
fclose(ff);

