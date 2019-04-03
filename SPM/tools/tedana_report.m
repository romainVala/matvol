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

count = 0;

ctable = zeros(0);
names  = cell(0);

for subj = 1 : length(comptable_file)
    
    success = 0;
    fail    = 0;
    
    for run = 1 : length(meinfo.path{subj})
        
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
            
            ctable(count,:) = [NaN NaN NaN Nan];
            
        end
        
        names{count}    = get_parent_path(strrep(comptable_file{subj}{run}, study_path, ''));
        
    end
    
    comptable_success(subj) = success;
    comptable_fail   (subj) = fail;
    
end


%% Convert to table

Table = array2table(ctable, 'VariableNames',{'Components', 'Accepted', 'Rejected', 'Ignored'}, 'RowNames', names);


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
    t.Data       = ctable;
    
    % Fig 2
    
    f2 = figure('Name',meinfo_file);
    ax = axes(f2);
    barh(ax,ctable(:,2:end),'stacked','DisplayName','ctable')
    ax.TickLabelInterpreter = 'none';
    ax.YTick      = 1 : size(ctable,1);
    ax.YTickLabel = names;
    
end


end % function
