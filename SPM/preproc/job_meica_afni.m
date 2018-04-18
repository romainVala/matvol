function [ job ] = job_meica_afni( dir_func, dir_anat, par )
%JOB_MEICA_AFNI


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

% defpar.file_reg      = '^f.*nii';
defpar.anat_file_reg = '^s.*nii';
defpar.subdir        = 'meica';

defpar.nrCPU         = 2;
defpar.pct           = 0;
defpar.sge           = 0;

defpar.redo          = 0;
defpar.fake          = 0;

defpar.verbose       = 1;


par = complet_struct(par,defpar);


parsge  = par.sge;
par.sge = -1; % only prepare commands

parverbose  = par.verbose;
par.verbose = 0; % don't print anything yet


%% Fetch data

assert( length(dir_func) == length(dir_anat), 'dir_func & dir_anat must be the same length' )

if iscell(dir_func{1})
    nrSubject = length(dir_func);
else
    nrSubject = 1;
end

job = cell(nrSubject,1);

fprintf('\n')

for subj = 1 : nrSubject
    
    % Extract subject name, and print it
    subjectName = get_parent_path(dir_func{subj}(1));
    
    % Echo in terminal & initialize job_subj
    fprintf('[%s]: Preparing JOB %d/%d for %s \n', mfilename, subj, nrSubject, subjectName{1});
    job_subj = {sprintf('#################### [%s] JOB %d/%d for %s #################### \n', mfilename, subj, nrSubject, dir_func{subj}{1})}; % initialize
    
    nrRun = length(dir_func{subj});
    
    nrEchoAllRuns = zeros(nrRun,1);
    
    working_dir = char(r_mkdir(subjectName,par.subdir));
    
    %-Anat
    %======================================================================
    
    % Make symbolic link of tha anat in the working directory
    A_src = char(get_subdir_regex_files( dir_anat{subj}, par.anat_file_reg, 1 ));
    assert( exist(A_src,'file')==2 , 'file does not exist : %s', A_src )
    
    % File extension ?
    if strcmp(A_src(end-6:end),'.nii.gz')
        ext = '.nii.gz';
    elseif strcmp(A_src(end-3:end),'.nii')
        ext = '.nii';
    else
        error('WTF ? supported files are .nii and .nii.gz')
    end
    anat_filename = sprintf('anat%s',ext);
    
    A_dst = fullfile(working_dir,anat_filename);
    r_movefile(A_src, A_dst, 'linkn');

    
    %-All echos
    %======================================================================
    
    for run = 1 : nrRun
        
        % Check if dir exist
        run_path = dir_func{subj}{run};
        assert( exist(run_path,'dir')==7 , 'not a dir : %s', run_path )
        fprintf('In run dir %s ', run_path);
        
        % Fetch json dics
        jsons = get_subdir_regex_files(run_path,'^dic.*json',struct('verbose',0));
        assert(~isempty(jsons), 'no ^dic.*json file detected in : %s', run_path)
        
        % Verify the number of echos
        nrEchoAllRuns(run) = size(jsons{1},1);
        assert( all( nrEchoAllRuns(1) == nrEchoAllRuns(run) ) , 'all dir_func does not have the same number of echos' )
        
        % Fetch all TE and reorder them
        res = get_string_from_json(cellstr(jsons{1}),'EchoTime','numeric');
        allTE = cell2mat([res{:}]);
        [sortedTE,order] = sort(allTE);
        fprintf(['TEs are : ' repmat('%g ',[1,length(allTE)]) ], allTE)
        
        % Fetch volume corrsponding to the echo
        allEchos = cell(length(order),1);
        for echo = 1 : length(order)
            if order(echo) == 1
                allEchos(echo) = get_subdir_regex_files(run_path,         '^f.*B\d.nii'                   , 1);
            else
                allEchos(echo) = get_subdir_regex_files(run_path, sprintf('^f.*B\\d_V%.3d.nii',order(echo)), 1);
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
                ext = '.nii.gz';
            elseif strcmp(E_src{echo}(end-3:end),'.nii')
                ext = '.nii';
            else
                error('WTF ? supported files are .nii and .nii.gz')
            end
            
            filename = sprintf('run%.3d_e%.3d%s',run,echo,ext);
            
            E_dst{echo} = fullfile(working_dir,filename);
            if ~exist(E_dst{echo},'file')
                r_movefile(E_src{echo}, E_dst{echo}, 'link');
            end
            
            E_dst{echo} = filename;
            
        end % echo
        
        
        %-Prepare command : meica.py
        %==================================================================
        
        data_sprintf = repmat('%s,',[1 length(E_dst)]);
        data_sprintf(end) = [];
        data_arg = sprintf(data_sprintf,E_dst{:});
        
        echo_sprintf = repmat('%g,',[1 length(sortedTE)]);
        echo_sprintf(end) = [];
        echo_arg = sprintf(echo_sprintf,sortedTE);
        
        cmd = sprintf('cd %s;\n meica.py -d %s -e %s -a %s --MNI --prefix %s --script_only \n\n',...
            working_dir, data_arg, echo_arg, anat_filename , sprintf('run%.3d',run) );
        
%         unix(cmd)
        
        %-Move meica-processed volumes in run dirs, using symbolic links
        %==================================================================
        
        
        
        
    end % run
    
    %-Move meica-processed anat in anat dir, using symbolic links
    %==================================================================
    
%     A__src = get_subdir_regex_files(working_dir,'anat_');
    
    
job(subj) = job_subj;

end % subj


end % function
