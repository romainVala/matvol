function varargout = meica_report( study_path, par )
% MEICA_REPORT will fetch subdir/meica/.*ctab.txt files
% Click on the table in the figure to print in the terminal the ctab.txt file.
%
% See also job_meica_afni


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end


defpar.subj_regex = '.*';        %
defpar.subdir     = '^meica$';     % name of the working dir
defpar.file_regex = 'ctab.txt$'; %
defpar.verbose    = 1;           % 0 : print nothing, 1 : print 2 first and 2 last messages, 2 : print all

par = complet_struct(par,defpar);


%% Fetch all ctab.ext

study_path = fullfile([study_path filesep],filesep); % make sure the last char is a 'filesep'

subjdir  = gdir ( study_path, par.subj_regex );
meicadir = gdir (    subjdir, par.subdir     );

if isempty(meicadir)
    warning( 'No [ %s ] dir found in %s[%s] \n', par.subdir, study_path, par.subj_regex )
    if nargout > 0
        varargout{1} = table;
    end
    return
end


%% Extract data

ctabfile = cell(size(meicadir));

count = 0;
for m = 1 : length(meicadir)
    tmp = gfile( meicadir{m}, par.file_regex , struct('verbose',0));
    if ~isempty(tmp)
        ctabfile(m) = tmp;
        for r = 1 : size(ctabfile{m},1)
            count = count + 1;
            filename = ctabfile{m}(r,:);
            content = get_file_content_as_char(filename);
            start = regexp(content, '##');
            stop  = regexp(content(start:end), '\n', 'once');
            line  = content(start + 2 : start+stop - 3);
            ctable(count,:) = cellfun(@str2double, strsplit(line)); %#ok<AGROW>
            RowNames{count,1} = regexprep(filename,study_path,''); %#ok<AGROW>
            ctabpath{count,1} = filename;  %#ok<AGROW>
        end
        
    else
        ctabfile{m} = '';
    end
    
end


%% Convert to table

Table = array2table(ctable, 'VariableNames',{'VEx','TCo','DFe','RJn','DFn'}, 'RowNames', RowNames);


%% Output

if nargout > 0
    varargout{1} = Table;
end

if par.verbose > 0
    
    disp(Table)
    
    fprintf('[%s] : found %d dirs using [%s] \n', mfilename, length(meicadir), par.subdir)
    
    vect = zeros(size(ctabfile));
    for c = 1 : length(ctabfile)
        vect(c) = size(ctabfile{c},1);
    end
    
    U = unique(vect);
    N = hist(vect,unique(vect));
    fprintf('Number of successful MEICA processing : \n')
    for p = 1 : length(U)
        fprintf('%d success x %d (%d%%) \n', U(p), N(p), round(100*N(p)/sum(N)))
    end
    
    figure('Name','Count of successful MEICA','NumberTitle','off');
    bar_ax   = subplot(1,1,1);
    bar(bar_ax,vect);
    bar_ax.TickLabelInterpreter = 'none';
    bar_ax.YTick = unique(vect);
    bar_ax.XTick = 1:length(meicadir);
    bar_ax.XTickLabel = regexprep(meicadir,study_path,'');
    bar_ax.XTickLabelRotation = 90;
    axis tight
    
end


%% Plot

if par.verbose > 0
    
    f=figure('Name','Count of successful MEICA','NumberTitle','off');
    
    t = uitable(f,...
        'UserData', ctabpath,...
        'Units','normalized',...
        'Position',[0 0 1 1],...
        'RowStriping','off',...
        'CellSelectionCallback',@CellSelectionCallback);
    
    t.ColumnName = Table.Properties.VariableNames;
    t.RowName    = Table.Properties.RowNames;
    t.Data       = ctable;
    
    fprintf('Click on the table in the figure to print in the terminal the ctab.txt file. \n')
    
end


end % function


%--------------------------------------------------------------------------
function CellSelectionCallback(src,event)

ctabfile = src.UserData;

x = event.Indices(1); % line
% y = event.Indices(2); % column

cprintf('blue','\n%s',ctabfile{x})
type(ctabfile{x});

end % function
