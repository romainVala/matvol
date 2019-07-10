function [ job ] = job_meica_afni( dir_func, dir_anat, par )
%JOB_MEICA_AFNI
% This script is well discribeded with the comments, just read it
%
% See also meica_report


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

% meica.py arguments : image processing
defpar.slice_timing  = 1;  % can be (1) (recommended, will fetch automaticaly the pattern in the dic_.*json), (0) or a (char) such as 'alt+z', check 3dTshift -help
defpar.MNI           = 0;  % Warp to MNI space using high-resolution template
defpar.space         = ''; % Path to specific standard space template for affine anatomical normalization
defpar.qwarp         = 0;  % Nonlinear anatomical normalization to MNI (or --space template) using 3dQWarp, after affine
defpar.no_skullstrip = 0;  % WARNING : Anatomical is already intensity-normalized and skull-stripped
defpar.no_despike    = 0;  % Do not de-spike functional data. Default is to de-spike, recommended.
defpar.smooth        = ''; % !!! Not recommended !!! Data FWHM smoothing (3dBlurInMask). Default off. ex: par.smooth='3mm'

% meica.py arguments : script options
defpar.script_only   = 0;  % Generate script only, then exit
defpar.pp_only       = 0;  % Preprocess only, then exit. It means no echo optimized comination, no ICA, just AFNI preprocessing
defpar.keep_int      = 0;  % Keep preprocessing intermediates. I don't see the use of it.
defpar.OVERWRITE     = 0;  % If subjdir/meica/meica.xyz directory exists, overwrite.
defpar.nrCPU         = 0;  % 0 means OpenMP will use all available CPU. If you want to parallelize jobs, use nrCPU=1 for each job.
defpar.cmd_arg       = ''; % Allows you to use all addition arguments not scripted in this job_meica_afni.m file

% matvol classic options
defpar.anat_file_reg = '^s_S\d{2}.*.nii'; % regex to fetch anat volume
defpar.subdir        = 'meica';   % name of the working dir
defpar.pct           = 0; % Parallel Computing Toolbox, will execute in parallel all the subjects
defpar.sge           = 0; % for ICM cluster, run the jobs in paralle
defpar.redo          = 0; % overwrite previous files
defpar.fake          = 0; % do everything exept running
defpar.verbose       = 2; % 0 : print nothing, 1 : print 2 first and 2 last messages, 2 : print all
defpar.jobname       = 'job_meica';

% report
defpar.report        = 0; % uses meica_report

par = complet_struct(par,defpar);


%% Setup that allows this scipt to prepare the commands only, no execution

parsge  = par.sge;
par.sge = -1; % only prepare commands

parverbose  = par.verbose;
par.verbose = 0; % don't print anything yet


%% Check dir_func architecture
% Transform dir_func into a multi-level cell
% Transform dir_anat into a cellstr (because only 1 anat per subj)

if ischar(dir_func)
    dir_func = cellstr(dir_func);
end

if ischar(dir_anat)
    dir_anat = cellstr(dir_anat);
end

if ischar(dir_func{1})
    if size(dir_func{1},1)>1
        dir_func = {cellstr(dir_func{1})};
    else
        dir_func = {dir_func};
    end
end


%% Other checks

if par.MNI == 0 && isempty(par.space) % native space
    warp = 'nat';
elseif par.MNI == 1 && isempty(par.space) % mni
    if par.qwarp % affine + non-linear
        warp = 'nlw';
    else % affine
        warp = 'afw';
    end
elseif par.MNI == 0 && ~isempty(par.space) % specific tempalte (non the defalut MNI for AFNI)
    if par.qwarp % affine + non-linear
        warp = 'nlw';
    else % affine
        warp = 'afw';
    end
elseif par.MNI == 1 && ~isempty(par.space)
    error('Cannot do --MNI + --space')
else
    warp = '';
end


%% Main

assert( length(dir_func) == length(dir_anat), 'dir_func & dir_anat must be the same length' )

nrSubject = length(dir_func);

job = cell(nrSubject,1); % pre-allocation, this is the job containter

fprintf('\n')

for subj = 1 : nrSubject
    
    % Extract subject name, and print it
    subjectName = get_parent_path(dir_func{subj}(1));
    
    % Echo in terminal & initialize job_subj
    fprintf('[%s]: Preparing JOB %d/%d for %s \n', mfilename, subj, nrSubject, subjectName{1});
    job_subj = sprintf('#################### [%s] JOB %d/%d for %s #################### \n', mfilename, subj, nrSubject, dir_func{subj}{1}); % initialize
    
    nrRun = length(dir_func{subj});
    
    % nrEchoAllRuns = zeros(nrRun,1);
    
    % Create the working dir
    working_dir = char(r_mkdir(subjectName,par.subdir));
    
    %-Anat
    %======================================================================
    
    % Make symbolic link of tha anat in the working directory
    assert( exist(dir_anat{subj},'dir')==7 , 'not a dir : %s', dir_anat{subj} )
    A_src = cellstr(char(get_subdir_regex_files( dir_anat{subj}, par.anat_file_reg, struct('verbose',0))));
    A_src = char(A_src{1}); % keep the first volume, with the shorter name
    
    job_subj = [job_subj sprintf('### Anat @ %s \n', dir_anat{subj}) ]; %#ok<*AGROW>
    
    % File extension ?
    if strcmp(A_src(end-6:end),'.nii.gz')
        ext_anat = '.nii.gz';
    elseif strcmp(A_src(end-3:end),'.nii')
        ext_anat = '.nii';
    else
        error('WTF ? supported files are .nii and .nii.gz')
    end
    
    [~, anat_name, ~] = fileparts(A_src(1:end-length(ext_anat))); % remove extension to parse the file name
    anat_filename = sprintf('%s%s',anat_name,ext_anat);
    
    A_dst = fullfile(working_dir,anat_filename);
    [ ~ , job_tmp ] = r_movefile(A_src, A_dst, 'linkn', par);
    job_subj = [job_subj char(job_tmp) sprintf('\n')];
    
    ext_anat = '.nii.gz'; % force this : AFNI only generates this .nii.gz volumes
    
    %-All echos
    %======================================================================
    
    for run = 1 : nrRun
        
        % Check if dir exist
        run_path = dir_func{subj}{run} ;
        if isempty(run_path), continue, end % empty string
        assert( exist(run_path,'dir')==7 , 'not a dir : %s', run_path )
        fprintf('In run dir %s ', run_path);
        [~, serie_name] = get_parent_path(run_path);
        
        job_subj = [job_subj sprintf('### Run %d/%d @ %s \n', run, nrRun, dir_func{subj}{run}) ];
        
        prefix = serie_name;
        
        if par.redo
            % pass
        elseif exist(fullfile(working_dir,[prefix '_ctab.txt']),'file') == 2
            fprintf('[%s]: skiping %s because %s exist \n',mfilename,run_path,'ctab.txt')
            continue
        end
        
        % Fetch json dics
        jsons = get_subdir_regex_files(run_path,'^dic.*json',struct('verbose',0));
        assert(~isempty(jsons), 'no ^dic.*json file detected in : %s', run_path)
        
        % % Verify the number of echos
        % nrEchoAllRuns(run) = size(jsons{1},1);
        % assert( all( nrEchoAllRuns(1) == nrEchoAllRuns(run) ) , 'all dir_func does not have the same number of echos' )
        
        % Fetch all TE and reorder them
        res = get_string_from_json(cellstr(jsons{1}),'EchoTime','numeric');
        allTE = cell2mat([res{:}]);
        [sortedTE,order] = sort(allTE);
        fprintf(['TEs are : ' repmat('%g ',[1,length(allTE)]) ], allTE)
        
        % Fetch volume corrsponding to the echo
        allEchos = cell(length(order),1);
        for echo = 1 : length(order)
            if order(echo) == 1
                allEchos(echo) = get_subdir_regex_files(run_path, ['^f\d+_' serie_name '.nii'], 1);
            else
                allEchos(echo) = get_subdir_regex_files(run_path, ['^f\d+_' serie_name '_' sprintf('V%.3d',order(echo)) '.nii'], 1);
            end
        end % echo
        fprintf(['sorted as : ' repmat('%g ',[1,length(sortedTE)]) 'ms \n'], sortedTE)
        
        % Make symbolic link of the echo in the working directory
        E_src = cell(length(allEchos),1);
        E_dst = cell(length(allEchos),1);
        for echo = 1 : length(allEchos)
            
            E_src{echo} = allEchos{echo};
            
            % File extension ?
            if strcmp(E_src{echo}(end-6:end),'.nii.gz')
                ext_echo = '.nii.gz';
            elseif strcmp(E_src{echo}(end-3:end),'.nii')
                ext_echo = '.nii';
            else
                error('WTF ? supported files are .nii and .nii.gz')
            end
            
            filename = sprintf('%s_e%.3d%s',prefix,echo,ext_echo);
            
            E_dst{echo} = fullfile(working_dir,filename);
            [ ~ , job_tmp ] = r_movefile(E_src{echo}, E_dst{echo}, 'linkn', par);
            job_subj = [job_subj char(job_tmp)];
            
            E_dst{echo} = filename;
            
            ext_echo = '.nii.gz'; % force this : AFNI only generates this .nii.gz volumes
            
        end % echo
        
        %-Prepare slice timing info
        %==================================================================
        
        if isnumeric(par.slice_timing) && par.slice_timing == 1
            
            % Read the slice timings directly in the dic_.*json
            [ out ] = get_string_from_json( deblank(jsons{1}(1,:)) , 'CsaImage.MosaicRefAcqTimes' , 'vect' ); % in milliseconds
            
            % Right field found ?
            assert( ~isempty(out{1}), 'Did not detect the right field ''CsaImage.MosaicRefAcqTimes'' in the file %s', deblank(jsons{1}(1,:)) )
            
            % Destination file :
            tpattern = fullfile(working_dir,'sliceorder.txt');
            fileID = fopen( tpattern , 'w' , 'n' , 'UTF-8' );
            if fileID < 0
                warning('[%s]: Could not open %s', mfilename, filename)
            end
            fprintf(fileID, '%f\n', out{1}/1000 ); % in seconds
            fclose(fileID);
            tpattern = ['@' tpattern]; % 3dTshift syntax to use a file is 3dTshift -tpattern @filename
            
        elseif ischar(par.slice_timing)
            
            tpattern = par.slice_timing;
            
        end
        
        % Fetch TR
        res = get_string_from_json( deblank(jsons{1}(1,:)) ,'RepetitionTime','numeric'); % in milliseconds
        TR = res{1}/1000; % in seconds
        
        %-Prepare command : meica.py
        %==================================================================
        
        data_sprintf = repmat('%s,',[1 length(E_dst)]);
        data_sprintf(end) = [];
        data_arg = sprintf(data_sprintf,E_dst{:}); % looks like : "path/to/echo1, path/to/echo2, path/to/echo3"
        
        echo_sprintf = repmat('%g,',[1 length(sortedTE)]);
        echo_sprintf(end) = [];
        echo_arg = sprintf(echo_sprintf,sortedTE); % looks like : "TE1, TE2, TE3"
        
        % Main command
        cmd = sprintf('cd %s;\n meica.py -d %s -e %s -a %s --prefix %s --cpus %d --TR=%g --daw=5',... % kdaw = 5 makes ICA converge much easier : https://bitbucket.org/prantikk/me-ica/issues/28/meice-ocnvergence-issue-mdpnodeexception
            working_dir, data_arg, echo_arg, anat_filename , prefix, par.nrCPU, TR );
        
        % Options :
        
        % SliceTiming Correction
        if ( isnumeric(par.slice_timing) && par.slice_timing == 1 ) || ischar(par.slice_timing)
            cmd = sprintf('%s --tpattern %s', cmd, tpattern);
        end
        
        if par.MNI,             cmd = sprintf('%s --MNI'          , cmd); end
        if ~isempty(par.space), cmd = sprintf('%s --space %s'     , cmd, par.space ); end
        if par.qwarp,           cmd = sprintf('%s --qwarp'        , cmd); end
        if par.no_skullstrip,   cmd = sprintf('%s --no_skullstrip', cmd); end
        if par.no_despike,      cmd = sprintf('%s --no_despike'   , cmd); end
        if par.smooth,          cmd = sprintf('%s --smooth %s'    , cmd, par.smooth); end
        if par.script_only,     cmd = sprintf('%s --script_only'  , cmd); end
        if par.pp_only,         cmd = sprintf('%s --pp_only'      , cmd); end
        if par.keep_int,        cmd = sprintf('%s --keep_int'     , cmd); end
        if par.OVERWRITE,       cmd = sprintf('%s --OVERWRITE'    , cmd); end
        
        % Other args ?
        if ~isempty(par.cmd_arg)
            cmd = sprintf('%s %s', cmd, par.cmd_arg);
        end
        
        % Finish preparing meica job
        cmd = sprintf('%s \n',cmd);
        job_subj = [job_subj cmd];
        
        %-Move meica-processed volumes in run dirs, using symbolic links
        %==================================================================
        
        list_volume_base = {
            '_hikts_'
            '_medn_'
            '_mefc_'
            '_mefcz_'
            '_mefl_'
            '_T1c_medn_'
            '_tsoc_'
            };
        
        list_volume_src = addprefixtofilenames(list_volume_base, prefix);      % add prefix
        list_volume_src = addsuffixtofilenames(list_volume_src,warp);          % add suffix for space
        list_volume_src = addsuffixtofilenames(list_volume_src,ext_echo);      % add file extension
        list_volume_src{end+1} = sprintf('%s_%s',prefix,'ctab.txt');           % components table
        list_volume_src{end+1} = sprintf('meica.%s_e001',prefix);              % for motion paramters path (1/2)
        list_volume_src{end+1} = sprintf('meica.%s_e001',prefix);              % for tsoc_nogs.nii (1/2)
        list_volume_src = addprefixtofilenames(list_volume_src,working_dir);
        list_volume_src{end-1} = fullfile( list_volume_src{end} , '/TED/tsoc_nogs.nii' ); % for motion paramters path (2/2)
        list_volume_src{end  } = fullfile( list_volume_src{end} , 'motion.1D' ); % for motion paramters path (2/2)
        
        list_volume_dst = addprefixtofilenames(list_volume_base,prefix);       % add prefix
        list_volume_dst = addsuffixtofilenames(list_volume_dst,warp);          % add suffix for space
        list_volume_dst = addsuffixtofilenames(list_volume_dst,ext_echo);      % add file extension
        list_volume_dst{end+1} = sprintf('%s_%s',prefix,'ctab.txt');           % components table
        list_volume_dst{end+1} = sprintf('%s_tsoc_nogs.nii',prefix);           % tsoc_nogs.nii : in case of TEDNA crach, we still have the TSoc
        list_volume_dst{end+1} = sprintf('rp_%s.txt',prefix);                  % motion paramters
        list_volume_dst = addprefixtofilenames(list_volume_dst,dir_func{subj}{run}); % path of the serie dir
        
        [ ~ , job_tmp ] = r_movefile(list_volume_src, list_volume_dst, 'linkn', par);
        job_subj = [job_subj [job_tmp{:}] sprintf('\n')];
        
    end % run
    
    %-Move meica-processed anat in anat dir, using symbolic links
    %==================================================================
    
    job_subj = [job_subj sprintf('### Anat @ %s \n', dir_anat{subj}) ];
    
    list_anat_base = {
        '_do' % deoblique
        '_u'  % unifize
        '_ns' % skullstrip
        };
    
    if strcmp(warp,'afw') || strcmp(warp,'nlw')
        list_anat_base = [ list_anat_base ; '_ns_at' ];
    end
    if strcmp(warp,'nlw')
        list_anat_base = [ list_anat_base ; '_ns_atnl' ; '_ns_atnl_WARP' ; '_ns_atnl_WARPINV' ];
    end
    
    list_anat_src = addprefixtofilenames(list_anat_base,anat_name);
    list_anat_src = addsuffixtofilenames(list_anat_src,ext_anat);
    if strcmp(warp,'afw') || strcmp(warp,'nlw'), list_anat_src{end+1} = 'anat_xns2at.aff12.1D'; end % coregistration paramters ?
    list_anat_src = addprefixtofilenames(list_anat_src,working_dir);
    
    list_anat_dst = addprefixtofilenames(list_anat_base,anat_name);
    list_anat_dst = addsuffixtofilenames(list_anat_dst,ext_anat);
    if strcmp(warp,'afw') || strcmp(warp,'nlw'), list_anat_dst{end+1} = 'anat_xns2at.aff12.1D'; end % coregistration paramters ?
    list_anat_dst = addprefixtofilenames(list_anat_dst,dir_anat{subj});
    
    [ ~ , job_tmp ] = r_movefile(list_anat_src, list_anat_dst, 'linkn', par);
    job_subj = [job_subj [job_tmp{:}]];
    
    % Save job_subj
    job{subj} = job_subj;
    
end % subj

% Now the jobs are prepared


%% Remove skipable jobs

skip = false(length(job),1);
for j = 1 : length(job)
    has_meica = ~isempty( strfind(job{j}, 'meica.py') );
    has_cd    = ~isempty( strfind(job{j}, 'cd ') );
    has_ln    = ~isempty( strfind(job{j}, 'ln -sf ') );
    if ~has_meica && ~has_cd && ~has_ln
        skip(j) = true;
    end
end

job(skip) = [];


%% Run the jobs

% Fetch origial parameters, because all jobs are prepared
par.sge     = parsge;
par.verbose = parverbose;

% Prepare Cluster job optimization
if par.sge
    if par.nrCPU == 0
        par.nrCPU = 7; % on the cluster, each node have 28 cores and 128Go of RAM
    end
    par.sge_nb_coeur = par.nrCPU;
    par.mem          = 2000*(par.sge_nb_coeur+1) ;
    par.walltime     = sprintf('%0.2d',nrRun); % roughtly 1h per run, in case of slow convergeance
end

% Run CPU, run !
job = do_cmd_sge(job, par);


%% Report

if par.report
    meica_report( fileparts(fileparts(fileparts(run_path))), par )
end


end % function
