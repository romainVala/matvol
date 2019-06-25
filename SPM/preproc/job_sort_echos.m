function [meinfo, jobs] = job_sort_echos( multilvl_funcdir , par )
%JOB_SORT_ECHOS
%
% INPUT
% - multilvl_funcdir is multi-level cell
%   level 1 : subj
%   level 2 : run
%
% OUTPUT
% - meinfo.full : multi-level cell containing structure the structure contains info about the sorted volumes (name, TE, ...)
% - meinfo.path : multi-level cell containing echos paths as cellstr
% - meinfo.TE   : multi-level cell containing TE as vecor
%
% see also get_subdir_regex get_subdir_regex_multi


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - multilvl_funcdir is required',mfilename)
end

% Make sure we have a multi-level cell
obj = 0;
if ischar(multilvl_funcdir)
    multilvl_funcdir = {cellstr(multilvl_funcdir)};
elseif iscell(multilvl_funcdir)
    multilvl_funcdir = cellfun(@cellstr, multilvl_funcdir, 'UniformOutput', 0);
elseif isa(multilvl_funcdir,'serie')
    obj = 1;
    in_obj  = multilvl_funcdir;
    multilvl_funcdir = multilvl_funcdir.toJob;
else
    error('not supported input : char, cell, cellstr, multi-level cell, @serie object array')
end


%% defpar

defpar.fname        = 'meinfo'; % ,neme of the .mat file that will be saved

defpar.sge          = 0;
defpar.jobname      = 'job_sort_echos';
defpar.walltime     = '00:30:00';
defpar.mem          = '1G';

defpar.auto_add_obj = 1;

defpar.verbose      = 1;
defpar.redo         = 0;
defpar.run          = 0;

par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end


%% Setup that allows this scipt to prepare the commands only, no execution

parsge  = par.sge;
par.sge = -1; % only prepare commands

parverbose  = par.verbose;
par.verbose = 0; % don't print anything yet


%% Check if already done

fname = fullfile( get_parent_path(multilvl_funcdir{1}{1},2) , [par.fname '.mat'] );

if exist(fname,'file')  &&  ~par.redo
    
    fprintf('[%s]: Found meinfo file : %s \n', mfilename, fname)
    
    l      = load(fname);
    meinfo = l.meinfo;
    jobs   = l.jobs;
    
    if obj && par.auto_add_obj
        add_obj(in_obj,meinfo)
    end
    
    return
end


%% Sort echos

nSubj = length(multilvl_funcdir);

jobs = cell(nSubj,1);
meinfo_full = jobs;
meinfo_path = jobs;
meinfo_TE   = jobs;
meinfo_TR   = jobs;
meinfo_so   = jobs;
for iSubj = 1 : nSubj
    
    % Extract subject name, and print it
    subjectName = get_parent_path(multilvl_funcdir{iSubj}(1));
    
    % Echo in terminal & initialize job_subj
    fprintf('[%s]: Preparing JOB %d/%d for %s \n', mfilename, iSubj, nSubj, subjectName{1});
    job_subj = sprintf('#################### [%s] JOB %d/%d for %s #################### \n', mfilename, iSubj, nSubj, multilvl_funcdir{iSubj}{1}); % initialize
    
    nRun = length(multilvl_funcdir{iSubj});
    
    meinfo_full{iSubj} = cell(nRun,1);
    meinfo_path{iSubj} = cell(nRun,1);
    meinfo_TE  {iSubj} = cell(nRun,1);
    meinfo_TR  {iSubj} = cell(nRun,1);
    meinfo_so  {iSubj} = cell(nRun,1);
    for iRun = 1 : nRun
        
        meinfo_full{iSubj}{iRun} = struct;
        
        run_path = multilvl_funcdir{iSubj}{iRun};
        
        % Check if dir exist
        if isempty(run_path), continue, end % empty string
        assert( exist(run_path,'dir')==7 , 'not a dir : %s', run_path )
        
        fprintf('In run dir %s ', run_path);
        [~, serie_name] = get_parent_path(run_path);
        
        job_subj = [job_subj sprintf('### Run %d/%d @ %s \n', iRun, nRun, run_path) ]; %#ok<*AGROW>
        
        % Fetch json dics
        jsons = get_subdir_regex_files(run_path,'^dic.*json$',struct('verbose',0));
        assert(~isempty(jsons), 'no ^dic.*json file detected in : %s', run_path)
        
        % Fetch all TE and reorder them
        res = get_string_from_json(cellstr(jsons{1}),{'EchoTime', 'RepetitionTime', 'CsaImage.MosaicRefAcqTimes'},{'num', 'num', 'vect'});
        allTE = zeros(size(jsons{1},1),1);
        for e = 1 : size(jsons{1},1)
            allTE(e) = res{e}{1};
            if e == 1
                TR = res{e}{2};
                sliceonsets = res{e}{3};
            end
        end
        [sortedTE,order] = sort(allTE);
        fprintf(['TEs are : '   repmat('%g ',[1,length(allTE)   ])        ], allTE)
        fprintf(['sorted as : ' repmat('%g ',[1,length(sortedTE)]) 'ms \n'], sortedTE)
        
        % Fetch volume corrsponding to the echo
        allEchos = cell(length(order),1);
        for echo = 1 : length(order)
            if order(echo) == 1
                allEchos(echo) = get_subdir_regex_files(run_path, ['^f\d+_' serie_name '.nii'], 1);
            else
                allEchos(echo) = get_subdir_regex_files(run_path, ['^f\d+_' serie_name '_' sprintf('V%.3d',order(echo)) '.nii'], 1);
            end
        end % echo
        
        % Make symbolic link of the echo in the working directory
        E_src = cell(length(allEchos),1);
        E_dst = cell(length(allEchos),1);
        for echo = 1 : length(allEchos)
            
            E_src{echo} = allEchos{echo};
            
            [pth,nam,ext] = spm_fileparts(E_src{echo});
            
            filename = sprintf('e%d%s',echo,ext);
            
            meinfo_full{iSubj}{iRun}(echo).pth     = pth;
            meinfo_full{iSubj}{iRun}(echo).ext     = ext;
            meinfo_full{iSubj}{iRun}(echo).inname  = nam;
            meinfo_full{iSubj}{iRun}(echo).outname = sprintf('e%d',echo);
            meinfo_full{iSubj}{iRun}(echo).TE      = sortedTE(echo);
            meinfo_full{iSubj}{iRun}(echo).fname   = fullfile( pth, sprintf('e%d%s',echo,ext) );
            meinfo_full{iSubj}{iRun}(echo).TR      = TR;
            meinfo_full{iSubj}{iRun}(echo).sliceonsets = sliceonsets;
            
            E_dst{echo} = fullfile(run_path,filename);
            [ ~ , job_tmp ] = r_movefile(E_src{echo}, E_dst{echo}, 'linkn', par);
            job_subj = [job_subj char(job_tmp)];
            
            E_dst{echo} = filename;
            
        end % echo
        
        meinfo_path{iSubj}{iRun} = {meinfo_full{iSubj}{iRun}.fname}';
        meinfo_TE  {iSubj}{iRun} = [meinfo_full{iSubj}{iRun}.TE];
        meinfo_TR  {iSubj}{iRun} =  meinfo_full{iSubj}{iRun}(1).TR;
        meinfo_so  {iSubj}{iRun} =  meinfo_full{iSubj}{iRun}(1).sliceonsets;
    end % iRun
    
    % Save job_subj
    jobs{iSubj} = job_subj;
    
end % iSubj

meinfo      = struct;
meinfo.full = meinfo_full;
meinfo.path = meinfo_path;
meinfo.TE   = meinfo_TE;
meinfo.TR   = meinfo_TR;
meinfo.sliceonsets = meinfo_so;


%% Run the jobs

% Fetch origial parameters, because all jobs are prepared
par.sge     = parsge;
par.verbose = parverbose;

jobs = do_cmd_sge(jobs, par);


%% Save info in file

if ( par.run || par.sge ) && ~par.fake
    save(fname, 'meinfo', 'jobs')
end


%% Add outputs objects

if obj && par.auto_add_obj && par.run
    add_obj(in_obj,meinfo)
end


end % function


function add_obj(in_obj,meinfo)

for iEcho = 1 : length(meinfo.full{1}{1})
    in_obj.addVolume(sprintf('^e%d.nii',iEcho),sprintf('e%d',iEcho))
end

end % function
