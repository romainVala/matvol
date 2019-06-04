function jobs= do_freesurfer_longitudinal(sujid,sujdirs,params)

if ~isfield(params,'sge_queu'),  params.sge_queu = 'long';end
if ~isfield(params,'skip'),  params.skip = 1; end
if ~isfield(params,'version'),  params.version = 5; end
if ~isfield(params,'version_path'),params.version_path='module load FreeSurfer/6.0.0';end
if ~isfield(params,'free_sujdir')
    [pr ff] = get_parent_path(anat,3);
    aa = r_mkdir(pr(1),'freesurfer');
    params.free_sujdir = aa{1};
    char(params.free_sujdir);
end


jobs = {}; jobs2={};

for nbsuj=1:length(sujid)
    
    %recon-all -base <templateid> -tp <tp1id> -tp <tp2id> ... -all
    
    %recon-all -long <tpNid> <templateid> -all
     
    if ~isempty(params.version_path)
        cmd = sprintf('%s \n',params.version_path)
    else
        if params.version == 5
                [a b]=unix('which freesurfer5') ;
                cmd = sprintf('source %s \n ',b);
               
        else
            cmd = sprintf('source /usr/cenir/bincenir/freesurfer; \n');
        end
    end

    cmd1 = sprintf('%s\n recon-all -all -base %s -sd %s',cmd,sujid{nbsuj},params.free_sujdir);
    
    for nbt=1:length(sujdirs{nbsuj})
        cmd1 = sprintf('%s -tp %s',cmd1,sujdirs{nbsuj}{nbt});
        cmd2 = sprintf('%s\n recon-all -long %s %s -all -sd %s\n',cmd,sujdirs{nbsuj}{nbt},sujid{nbsuj},params.free_sujdir);
        % with extra arg todo
	%cmd2 = sprintf('%s\n recon-all -long %s %s -all -sd %s -brainstem-structures \n',cmd,sujdirs{nbsuj}{nbt},sujid{nbsuj},params.free_sujdir);
        jobs2{end+1} = cmd2; 
    end
        
    jobs{end+1} = cmd1;        
    
end


if ~isempty(jobs)
    %if isempty(job_dir), params.job_dir = proot; end
    params.jobname = 'freesurfer_reconbase';
    [j fqsub] = do_cmd_sge(jobs,params);
    
    params.jobname = 'freesurfer_reconbase_last';
    do_cmd_sge(jobs2,params,'',fqsub);
    
end

% %redoo
%  sujdir_freesurfer={}; sid = {};
% sslong= addsuffixtofilenames(ss,'.*long');
% ssfirst=addsuffixtofilenames(ss,'..*');
% for nbs=1:length(ss)
%     done{nbs}  =  get_subdir_regex(rd,sslong(nbs),'mri');
%     if isempty(done)
%         [pp sujdir_freesurfer{end+1}]  =  get_parent_path(get_subdir_regex(rd,ssfirst(nbs)));
%         sid{end+1} = ss{nbs};
%     end
% end
% 
% do_freesurfer_longitudinal(sid,sujdir_freesurfer,par)
