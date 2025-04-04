function  fqsub = split_dependency_job(fqsub, nbr)
% SPLIT_DEPENDENCY_JOB
%
% This function splits a jobs into two subgroups using a parameter "nbr". The
% first subgroup includes jobs from the start of the list up to and including
% the "nbr" position. The second subgroup starts with the job at "nbr + 1" 
% and goes to the end of the list. The jobs in the second subgroup only run 
% after all the jobs in the first subgroup are finished. 
% Note that this function only applies this splitting to the last group or
% subgroup founded in the input file "do_qsub".
%
% Inputs 
%        fqsub    : path to file do_qsub
%        nbr      : to split a list of jobs into two subgroups
%



[~, slurm_cmds] = unix(['cat ' fqsub]);

cmds = splitlines(slurm_cmds);
if isempty(cmds{end})
    cmds(end) = []
end 
    
% Change array number in the last line, which is last job group, if the file is
% modified
arguments = split(cmds(end-1),' ');
arguments_lastGroup = arguments;



index     = contains(arguments, '--array=');
assert(any(index),'No --array argument in the command');


newind = (find(index == 1));   % just to check

grps = str2num(char(split(erase(arguments{newind(end)},'--array='),'-'))); 
assert(any(nbr == [grps(1):grps(2)]), 'The number of jobs does not correspond to the composition index');


arguments{newind(end)}           = sprintf('--array=%d-%d',grps(1),nbr);
arguments_lastGroup{newind(end)} = sprintf('--array=%d-%d  --depend=afterok:$jobid',nbr + 1, grps(2));

cmds{end-1}   = sprintf('%s ',arguments{:});
cmds{end+1}   = sprintf('%s ',arguments_lastGroup{:})
cmds{end+1}   = sprintf('echo submitted job $jobid');
new_slurm_cmds =  sprintf('%s\n',cmds{:});

fid_qsub_file=fopen(fqsub,'w');

fprintf(fid_qsub_file,'%s',new_slurm_cmds);

fclose(fid_qsub_file);



end