function varargout = tedana_report( study_path, par )
% TEDANA_REPORT will fetch comp_table_ica.txt to make some stats report.
%
%
% See also job_tedana


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - study_path is required',mfilename)
end

defpar.verbose    = 1;           % 0 : print nothing, 1 : print 2 first and 2 last messages, 2 : print all

par = complet_struct(par,defpar);


%% Fetch all ctab.ext

study_path = fullfile([study_path filesep],filesep); % make sure the last char is a 'filesep'

meinfo_file = fullfile(study_path, 'meinfo.mat');

if ~exist(meinfo_file, 'file')
    warning( 'No "meinfo.mat" file found in %s \n', par.subdir, study_path )
    if nargout > 0
        varargout{1} = [];
    end
    return
end


%% Extract data

meinfo = load(meinfo_file);
meinfo = meinfo.meinfo;

comptable_file    = cell(size(meinfo.path));
comptable_success = nan(size(meinfo.path));
comptable_fail    = nan(size(meinfo.path));

log_file          = cell(size(meinfo.path));

count = 0;

ctable     = zeros(0,4);
names      = cell(0);
ICAattempt = zeros(0,2);

for subj = 1 : length(comptable_file)
    
    success = 0;
    fail    = 0;
    
    for run = 1 : length(meinfo.path{subj})
        
        % Component table -------------------------------------------------
        
        comptable_file{subj}{run} = fullfile( get_parent_path( meinfo.path{subj}{run}{1} ), 'comp_table_ica.txt' );
        
        count = count + 1;
        
        if exist( comptable_file{subj}{run}, 'file')
            
            success = success + 1;
            
            % Read the file as table
            warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames')
            T = readtable(comptable_file{subj}{run},'Delimiter','tab');
            warning('ON' , 'MATLAB:table:ModifiedAndSavedVarnames')
            
            nComponents = size(T,1);
            nAccepted   = sum(T.classification == "accepted");
            nRejected   = sum(T.classification == "rejected");
            nIgnored    = sum(T.classification == "ignored");
            
            assert( (nAccepted + nRejected + nIgnored) == nComponents , 'Houston we have a problem...' )
            
            ctable(count,:) = [nComponents nAccepted nRejected nIgnored];
            
        else
            
            fail    = fail    + 1;
            
            ctable(count,:) = [NaN NaN NaN NaN];
            
        end
        
        names{count}    = get_parent_path(strrep(comptable_file{subj}{run}, study_path, ''));
        
        % Log file --------------------------------------------------------
        
        log_file{subj}{run} = fullfile( get_parent_path( meinfo.path{subj}{run}{1} ), 'tedana.log' );
        
        if exist( log_file{subj}{run}, 'file')
            
            content = get_file_content_as_char(log_file{subj}{run});
            lines = strsplit(content,sprintf('\n'))';
            converged = ~cellfun(@isempty, strfind(lines,'converged in') ); %#ok<*STRCLFH>
            ICA_lines = ~cellfun(@isempty, strfind(lines,'ICA attempt' ) );
            
            if any(converged) % yes ! it converged !
                
                converge_line = lines{converged};
                res = regexp(converge_line, 'ICA attempt (?<attempt>\d+) converged in (?<iteration>\d+) iterations', 'names');
                assert(~isempty(res),'wrong interpretation of ICA converged attempt in %s', log_file{subj}{run})
                ICAattempt(count,1:2) = [str2double(res.attempt) str2double(res.iteration)];
                
            else % no it didn't ...
                
                ICA_failed = lines(ICA_lines);
                last_ICA   = ICA_failed{end};
                res = regexp(last_ICA, 'ICA attempt (?<attempt>\d+) failed to converge after (?<iteration>\d+) iterations', 'names');
                assert(~isempty(res),'wrong interpretation of ICA attempt in %s', log_file{subj}{run})
                ICAattempt(count,1:2) = [str2double(res.attempt) str2double(res.iteration)];
                
            end
            
        else
            
            ICAattempt(count,1:2) = [NaN NaN];
            
        end
        
    end
    
    comptable_success(subj) = success;
    comptable_fail   (subj) = fail;
    
end


%% Convert to table

data = [ICAattempt ctable];

Table = array2table(data, 'VariableNames',{'Attempty', 'Iterations','Components', 'Accepted', 'Rejected', 'Ignored'}, 'RowNames', names);


%% Output

if nargout > 0
    varargout{1} = Table;
end


%% Plot

if par.verbose > 0
    
    % Fig 1
    
    f1 = figure('Name',meinfo_file);
    
    t = uitable(f1,...
        'UserData', Table,...
        'Units','normalized',...
        'Position',[0 0 1 1],...
        'RowStriping','off');
    
    t.ColumnName = Table.Properties.VariableNames;
    t.RowName    = Table.Properties.RowNames;
    t.Data       = data;
    
    % Fig 2
    
    f2 = figure('Name',meinfo_file);
    ax = axes(f2);
    barh(ax,flipud(ctable(:,2:end)),'stacked','DisplayName','ctable')
    ax.TickLabelInterpreter = 'none';
    ax.YTick      = 1 : size(ctable,1);
    ax.YTickLabel = fliplr(names);
    
end


end % function
