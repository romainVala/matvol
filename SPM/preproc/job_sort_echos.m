function [meinfo, jobs] = job_sort_echos( multilvl_funcdir , par )
% JOB_SORT_ECHOS
%
% SYNTAX
% [meinfo, jobs] = JOB_SORT_ECHOS( multilvl_funcdir , par )
%
% EXAMPLE
% meinfo = JOB_SORT_ECHOS( examArray.getSerie('run') , par );
%
% INPUT
% - @serie array ( nSubj x nSerie ) // ex : get it with < e.getSereie('run') >
% OR
% - multilvl_funcdir is multi-level cell
%   level 1 : subj
%   level 2 : run
%
% OUTPUT
%  - meinfo.data   : multi-level cell containing structure the structure contains info about the sorted volumes (name, TE, ...)
% [- meinfo.volume : @volume array for e1.nii(.gz), e2.nii(.gz), e3.nii(.gz), ...]
%
% see also get_subdir_regex get_subdir_regex_multi exam exam.AddSerie serie.addVolume

if nargin==0, help(mfilename), return, end


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
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

% cluster
defpar.sge          = 0;
defpar.jobname      = 'job_sort_echos';
defpar.walltime     = '00:30:00';
defpar.mem          = '1G';

% matvol classics
defpar.run          = 1;
defpar.verbose      = 1;
defpar.redo         = 0;
defpar.auto_add_obj = 1;

par = complet_struct(par,defpar);


%% Setup that allows this scipt to prepare the commands only, no execution

parsge  = par.sge;
par.sge = -1; % only prepare commands

parverbose  = par.verbose;
par.verbose = 0; % don't print anything yet


%% Sort echos

nSubj    = length(multilvl_funcdir);

fnames       = cell( nSubj , 1 );
meinfo_      = struct; % => this meinfo_ structure is the one with all subjects
meinfo_.data = cell( nSubj , 1 );
jobs         = cell( nSubj , 1 );
to_write     = true( nSubj , 1);
skip         = [];

for iSubj = 1 : nSubj
    
    % Generate fullpath of filename meinfo.mat for each subj
    fnames{iSubj} = get_parent_path( multilvl_funcdir{iSubj}{1} );
    fnames{iSubj} = fullfile( fnames{iSubj} , [par.fname '.mat'] );
    
    fname = fnames{iSubj};
    
    % Check if the file exists
    if exist(fname,'file')  &&  ~par.redo
        
        fprintf('[%s]: Found meinfo file : %s \n', mfilename, fname)
        
        % Load file content
        l                   = load(fname);
        meinfo_.data{iSubj} = l.meinfo.data;
        if obj, meinfo_.volume(iSubj,:,:) = l.meinfo.volume; end
        to_write    (iSubj) = false;
        
        skip = [skip iSubj];
        
        continue
        
    end
    
    % Extract subject name, and print it
    subjectName = get_parent_path(multilvl_funcdir{iSubj}(1));
    
    % Echo in terminal & initialize job_subj
    fprintf('[%s]: Preparing JOB %d/%d for %s \n', mfilename, iSubj, nSubj, subjectName{1});
    job_subj = sprintf('#################### [%s] JOB %d/%d for %s #################### \n', mfilename, iSubj, nSubj, multilvl_funcdir{iSubj}{1}); % initialize
    
    nRun = length(multilvl_funcdir{iSubj});
    
    for iRun = 1 : nRun
        
        meinfo_.data{iSubj}{iRun,1} = struct;
        
        run_path = multilvl_funcdir{iSubj}{iRun};
        
        % Check if dir exist
        if isempty(run_path), continue, end % empty string
        assert( exist(run_path,'dir')==7 , 'not a dir : %s', run_path )
        
        fprintf('In run dir %s ', run_path);
        [~, serie_name] = get_parent_path(run_path);
        
        job_subj = [job_subj sprintf('### Run %d/%d @ %s \n', iRun, nRun, run_path) ]; %#ok<*AGROW>
        
        % Fetch json dics
        jsons = get_subdir_regex_files(run_path,'json$',struct('verbose',0));
        assert(~isempty(jsons), 'no .json file detected in : %s', run_path)
        
        jsons = cellstr(jsons{1});
        
        is_dcmstack = ~cellfun('isempty',regexp(jsons, 'dic_param_.*json$'));
        is_dcm2niix = ~cellfun('isempty',regexp(jsons,         'v_.*json$'));
        
        json_dcmstack = jsons(is_dcmstack);
        json_dcm2niix = jsons(is_dcm2niix);
        
        if numel(json_dcmstack)>0 && numel(json_dcm2niix)==0
            
            % Fetch all TE and reorder them
            res = get_string_from_json(json_dcmstack,{'EchoTime', 'RepetitionTime', 'CsaImage.MosaicRefAcqTimes'},{'num', 'num', 'vect'});
            allTE = zeros(size(json_dcmstack));
            for e = 1 : numel(json_dcmstack)
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
            
        elseif numel(json_dcm2niix)>0 && numel(json_dcmstack)==0
            
            % Fetch all TE and reorder them
            res   =  cell(size(json_dcm2niix));
            allTE = zeros(size(json_dcm2niix));
            for e = 1 : numel(json_dcm2niix)
                % I cannot save in a strcutre because of conversion problem : the json files do not always have the same fields
                res  {e} = spm_jsonread(json_dcm2niix{e});
                allTE(e) = res{e}.EchoTime       * 1000; % s -> ms
            end
            TR           = res{1}.RepetitionTime * 1000; % s -> ms
            sliceonsets  = res{1}.SliceTiming    * 1000; % s -> ms
            [sortedTE,order] = sort(allTE);
            fprintf(['TEs are : '   repmat('%g ',[1,length(allTE)   ])        ],    allTE)
            fprintf(['sorted as : ' repmat('%g ',[1,length(sortedTE)]) 'ms \n'], sortedTE)
            
            % Fetch volume corrsponding to the echo
            allEchos = get_subdir_regex_files(run_path, '^v_.*nii', numel(allTE));
            allEchos = cellstr(allEchos{1});
            allEchos = allEchos(order);
            
        else
            error('pb with the json files, please check the files and the code of this function')
        end
        
        
        
        % Make symbolic link of the echo in the working directory
        E_src = cell(length(allEchos),1);
        E_dst = cell(length(allEchos),1);
        for echo = 1 : length(allEchos)
            
            E_src{echo} = allEchos{echo};
            
            [pth,nam,~] = spm_fileparts(E_src{echo});
            ext = file_ext(E_src{echo});
            
            filename = sprintf('e%d%s',echo,ext);
            
            meinfo_.data{iSubj}{iRun,1}(echo).pth         = pth;
            meinfo_.data{iSubj}{iRun,1}(echo).ext         = ext;
            meinfo_.data{iSubj}{iRun,1}(echo).inname      = nam;
            meinfo_.data{iSubj}{iRun,1}(echo).outname     = sprintf('e%d',echo);
            meinfo_.data{iSubj}{iRun,1}(echo).TE          = sortedTE(echo);
            meinfo_.data{iSubj}{iRun,1}(echo).fname       = fullfile( pth, sprintf('e%d%s',echo,ext) );
            meinfo_.data{iSubj}{iRun,1}(echo).TR          = TR;
            meinfo_.data{iSubj}{iRun,1}(echo).sliceonsets = sliceonsets;
            
            E_dst{echo} = fullfile(run_path,filename);
            [ ~ , job_tmp ] = r_movefile(E_src{echo}, E_dst{echo}, 'linkn', par);
            job_subj = [job_subj char(job_tmp)];
            
            E_dst{echo} = filename;
            
        end % echo
        
        
    end % iRun
    
    % Save job_subj
    jobs{iSubj} = job_subj;
    
end % iSubj


%% Run the jobs

% Fetch origial parameters, because all jobs are prepared
par.sge     = parsge;
par.verbose = parverbose;

jobs(skip) = [];

jobs = do_cmd_sge(jobs, par);


%% Add outputs objects

if obj && par.auto_add_obj && (par.run || par.sge)
    
    for iSubj = 1 : length(meinfo_.data)
        for iRun = 1 : length(meinfo_.data{iSubj})
            for iEcho = 1 : length(meinfo_.data{iSubj}{iRun})
                
                % Shortcut
                echo = meinfo_.data{iSubj}{iRun}(iEcho);
                
                % Fetch the good serie
                % In case of empty element in in_obj, this "weird" strategy is very robust.
                serie = in_obj.getVolume( echo.pth ,'path').removeEmpty.getOne.serie;
                
                if par.run     % use the normal method
                    serie.addVolume( ['^' echo.outname echo.ext '$'] , sprintf('e%d',iEcho), 1 );
                elseif par.sge % add the new volume in the object manually, because the file is not created yet
                    serie.volume(end + 1) = volume( echo.fname, sprintf('e%d',iEcho), serie.exam, serie );
                end
                
            end % iEcho
        end % iRun
    end % iSubj
    
    meinfo_.volume = in_obj.getVolume('^e\d+$');
    
end


%% Save info in file

if ( par.run || par.sge ) && ~par.fake
    
    for iSubj = 1 : nSubj
        
        if to_write(iSubj)
            meinfo      = struct; % local
            meinfo.data = meinfo_.data{iSubj};
            if obj
                meinfo.volume = in_obj(iSubj,:).getVolume('^e\d+$'); %#ok<STRNU>
            end
            save(fnames{iSubj}, 'meinfo')
        end
        
    end % iSubj
    
end

% Output of the function is the "general" one, with all subjects
meinfo = meinfo_;


end % function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = file_ext(in)

% File extension ?
if strcmp(in(end-6:end),'.nii.gz')
    out = '.nii.gz';
elseif strcmp(in(end-3:end),'.nii')
    out = '.nii';
else
    error('WTF ? supported files are .nii and .nii.gz')
end

end % function
