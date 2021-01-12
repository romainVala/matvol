function job = job_afni_proc_single_echo( input_volume , par )
% JOB_AFNI_PROC_SINGLE_ECHO - AFNI:afni_proc.py
%
% SYANTX :
% job = JOB_AFNI_PROC_MULTI_ECHO( input_volume , par )
%
% EXAMPLE
% JOB_AFNI_PROC_MULTI_ECHO( input_volume , par );
%
% UNPUTS :
% - input_volume : can be 'char' of dir, multi-level 'cellstr' of dir, '@volume' array
% - par          : classic matvol parameter structure
%
% IMPORTANT note : please check the **defpar** section for all parameters
%
% See also job_sort_echos get_subdir_regex get_subdir_regex_files exam exam.AddSerie serie.addVolume

if nargin==0, help(mfilename), return, end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


obj = 0;
if isa(input_volume,'volume')
    obj = 1;
    volumeArray = input_volume;
end


%% defpar

defpar.blocks   = {'volreg'}; % now codded : despike, volreg
%defpar.seperate = 0;                             % each volume is treated seperatly : useful when runs have different orientations
defpar.execute  = 1;                             % execute afni_proc.py generated tcsh script file immidatly after the generation

defpar.write_nifti = 1;                          % convert afni_proc outputs .BRIK .HEAD to .nii .nii.gz

defpar.OMP_NUM_THREADS = 0;                      % number of CPU threads : 0 means all CPUs available

% cluster
defpar.sge      = 0;
defpar.subdir   = 'afni';                        % subdir is mandatory, because afni_proc creates a lot of files
defpar.jobname  = 'job_afni_proc_single_echo';
defpar.mem      = '4G';                          % AFNI is memory efficient, even with huge data
defpar.walltime = '08';                          % 8h computation max for 8 runs MEMB runs

% matvol classics
defpar.redo         = 0;
defpar.run          = 1;
defpar.verbose      = 1;
defpar.pct          = 0;
defpar.auto_add_obj = 1;                         % works with par.sge=1 for workflow preparation

par = complet_struct(par,defpar);

if par.sge || par.pct
    par.OMP_NUM_THREADS = 1; % in case of parallelization, only use 1 thread per job
end


% %% Seperate ? then we need to reformat meinfo
%
% if par.seperate
%
%     meinfo_orig = input_volume; % make a copy
%
%     j = 0; % job
%
%     meinfo_new = struct;
%
%     for iSubj =  1 : size(input_volume.data,1)
%         for iRun = 1 : length(input_volume.data{iSubj})
%
%             j = j + 1;
%
%             meinfo_new.data{j,1}{1} = meinfo_orig.data{iSubj}{iRun};
%             if isfield(meinfo_orig,'volume'), meinfo_new.volume(j,1,:) = meinfo_orig.volume(iSubj,iRun,:); end
%
%         end % iRun
%         if isfield(meinfo_orig,'anat'  ), meinfo_new.anat   = meinfo_orig.anat  ; end
%     end % iSubj
%
%     input_volume = meinfo_new; % swap
%
% end


%% Setup that allows this scipt to prepare the commands only, no execution

parsge  = par.sge;
par.sge = -1; % only prepare commands

parverbose  = par.verbose;
par.verbose = 0; % don't print anything yet


%% afni_proc.py

% obj : unzip if necesary
if obj
    input_volume = volumeArray.toJob(1);
end

prefix = char(par.blocks); % {'despike', 'tshift', 'volreg'}
prefix = prefix(:,1)';
prefix = fliplr(prefix);   % 'vtd'

nSubj = length(input_volume);
job   = cell(nSubj,1);
skip  = [];

for iSubj = 1 : nSubj
    
    %----------------------------------------------------------------------
    % Prepare job
    %----------------------------------------------------------------------
    
    input_volume{iSubj} = cellstr( char( input_volume{iSubj} ) );
    assert( length(input_volume{iSubj}) == 1, 'this function is not coded for multiple run per subject' )
    
    
    subj_path = get_parent_path(input_volume{iSubj}{1});
    
    %     if par.seperate
    %         [~,subj_name,~] = fileparts(subj_path);
    %         run_path        = input_volume.data{iSubj}{1}(1).pth;
    %         [~,run_name,~]  = fileparts(run_path);
    %         subj_name       = sprintf('%s__%s',subj_name,run_name);
    %         working_dir     = fullfile(run_path,par.subdir);
    %         real_path       = run_path;
    %     else
    [~,subj_name,~] = fileparts( input_volume{iSubj}{1});
    working_dir     = fullfile(subj_path,par.subdir);
    real_path       = subj_path;
    %     end
    
    if ~par.redo  &&  exist(working_dir,'dir')==7
        fprintf('[%s]: skiping %d/%d because %s exist \n', mfilename, iSubj, nSubj, working_dir);
        job{iSubj,1} = '';
        skip = [skip iSubj]; %#ok<AGROW>
        continue
    elseif exist(working_dir,'dir')==7
        rmdir(working_dir,'s')
    end
    
    fprintf('[%s]: Preparing JOB %d/%d @ %s \n', mfilename, iSubj, nSubj, real_path);
    cmd = sprintf('#################### [%s] JOB %d/%d @ %s #################### \n', mfilename, iSubj, nSubj, real_path); % initialize
    
    %----------------------------------------------------------------------
    % afni_proc.py basics
    %----------------------------------------------------------------------
    
    cmd = sprintf('%s export OMP_NUM_THREADS=%d;       \n', cmd, par.OMP_NUM_THREADS); % multi CPU option
    cmd = sprintf('%s cd %s;                           \n', cmd, real_path   );        % go to subj dir so afni_proc tcsh script is written there
    cmd = sprintf('%s afni_proc.py -subj_id %s     \\\\\n', cmd, subj_name  );         % subj_id is almost mendatory with afni
    cmd = sprintf('%s -out_dir %s                  \\\\\n', cmd, working_dir);         % afni working dir
    cmd = sprintf('%s -scr_overwrite               \\\\\n', cmd);                      % overwrite previous afni_proc tcsh script, if exists
    
    % add datasets
    for iRun = 1 : length(input_volume{iSubj})
        cmd = sprintf('%s -dsets %s \\\\\n', cmd, input_volume{iSubj}{iRun});
    end % iRun
    
    % blocks
    blocks = strjoin(par.blocks, ' ');
    cmd    = sprintf('%s -blocks %s \\\\\n',cmd, blocks);
    nBlock = 0; % manually manage the block number : some does generate volumes, some does not
    
    %----------------------------------------------------------------------
    % Blocks options
    %----------------------------------------------------------------------
    
    % despike
    if strfind(blocks, 'despike') %#ok<*STRIFCND>
        nBlock = nBlock + 1;
    end
    
    %     % tshift
    %     if strfind(blocks, 'tshift')
    %
    %         nBlock = nBlock + 1;
    %         cmd    = sprintf('%s -tshift_interp -heptic \\\\\n', cmd);
    %
    %         % TR & slice onsets
    %         sliceonsets = input_volume.data{iSubj}{iRun}(1).sliceonsets / 1000; % millisecond -> second;
    %         TR =  input_volume.data{iSubj}{iRun}(1).TR / 1000;
    %         tpattern = fullfile(subj_path,'sliceonsets.txt'); % destination file
    %         fileID = fopen( tpattern , 'w' , 'n' , 'UTF-8' );
    %         if fileID < 0
    %             warning('[%s]: Could not open %s', mfilename, filename)
    %         end
    %         fprintf(fileID, '%f\n', sliceonsets ); % in seconds
    %         fclose(fileID);
    %         cmd = sprintf('%s -tshift_opts_ts -TR %g -tpattern @%s \\\\\n', cmd, TR, tpattern);
    %
    %     end
    
    %     % align
    %     if strfind(blocks, 'align')
    %         % no volume generated, do not increment nBlock
    %         cmd = sprintf('%s -copy_anat %s                                              \\\\\n', cmd, anat{iSubj});
    %         cmd = sprintf('%s -volreg_align_e2a                                          \\\\\n', cmd             );
    %         cmd = sprintf('%s -align_opts_aea -ginormous_move -cost lpc+ZZ -resample off \\\\\n', cmd             );
    %     end
    
    % volreg
    if strfind(blocks, 'volreg')
        nBlock = nBlock + 1;
        cmd    = sprintf('%s -volreg_warp_final_interp wsinc5     \\\\\n', cmd);
        cmd    = sprintf('%s -volreg_align_to MIN_OUTLIER         \\\\\n', cmd);
        cmd    = sprintf('%s -volreg_interp -quintic              \\\\\n', cmd);
        cmd    = sprintf('%s -volreg_zpad 4                       \\\\\n', cmd);
        cmd    = sprintf('%s -volreg_opts_vr -nomaxdisp           \\\\\n', cmd); % this step takes way too long on the cluster
        % cmd    = sprintf('%s -volreg_post_vr_allin yes            \\\\\n', cmd); % per run alignment, like align_center ?
        % cmd    = sprintf('%s -volreg_pvra_base_index MIN_OUTLIER  \\\\\n', cmd);
    end
    
    % Execute the batch generated by afni_proc.py -------------------------
    if par.execute
        cmd = sprintf('%s -execute \\\\\n', cmd);
    end
    
    % ALWAYS end with cariage return
    cmd = sprintf('%s \n', cmd);
    
    %----------------------------------------------------------------------
    % Convert processed echos to nifi
    %----------------------------------------------------------------------
    
    if par.write_nifti
        
        for iRun = 1 : length(input_volume{iSubj})
            in  = fullfile(working_dir, sprintf('pb%0.2d.%s.r%0.2d.%s+*', nBlock, subj_name, iRun, par.blocks{end}) );
            out = addprefixtofilenames(input_volume{iSubj}{iRun}, prefix);
            cmd = sprintf('%s 3dAFNItoNIFTI -verb -verb -prefix %s %s \n', cmd, out, in);
        end % iRun
        
    end
    
    %----------------------------------------------------------------------
    % Save job
    %----------------------------------------------------------------------
    
    job{iSubj,1} = cmd;
    
    
end % iSubj

job(skip) = [];


%% Run the jobs

% Fetch origial parameters, because all jobs are prepared
par.sge     = parsge;
par.verbose = parverbose;

% Prepare Cluster job optimization
if par.sge
    if par.OMP_NUM_THREADS == 0
        par.OMP_NUM_THREADS = 1; % on the cluster, each node have 28 cores and 128Go of RAM
    end
    par.sge_nb_coeur = par.OMP_NUM_THREADS;
end

% Run CPU, run !
job = do_cmd_sge(job, par);


%% Add outputs objects

if obj && par.auto_add_obj && (par.run || par.sge)
    
    for iSubj = 1 : length(input_volume)
        for iRun = 1 : length(input_volume{iSubj})
            
            %             % Fetch the good serie
            %             % In case of empty element in in_obj, this "weird" strategy is very robust.
            %             if par.seperate
            %                 serie  = input_volume.volume(iSubj,1,1).serie;
            %             else
            vol = volumeArray(iSubj,1);
            ser = vol.serie;
            tag = vol.tag;
            sub = vol.subdir;
            %             end
            
            if par.run
                ext  = '.*.nii';
                ser.addVolume(sub, ['^' prefix tag ext],[prefix tag],1)
            elseif par.sge
                ser.addVolume('root', addprefixtofilenames(vol.path,prefix),[prefix tag],1)
            end
            
        end % iRun
    end % iSubj
    
end


end % function
