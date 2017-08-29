function addSeries( examArray, varargin)
% General syntax : examArray.addSeries( 'dir_regex_1', 'dir_regex_2', ... , {'tag_1', 'tag_2', ...}, N );
%
% Example :
%
% examArray.addSeries( 'PA$', {'run1', 'run2'} );
% is equivalent to
% examArray.addSeries( 'PA$', {'run1', 'run2'}, 2 );
%
% examArray.addSeries( 'PA$', 'run' );
% will auto increment run_001, run_002, ... for all dir_found
% it differes from :
% examArray.addSeries( 'PA$', 'run', 2 );
% will auto increment run_001, run_002, but error if nr_dir_found ~= 2


%% Check inputs

AssertIsExamArray(examArray);

% Need at least dir_regex + tag
assert( length(varargin)>=2 , '[%s]: requires at least 2 input arguments dir_regex + tag')

% nrSeries defined ?
if isnumeric( varargin{end} )
    nrSeries = varargin{end};
    assert( nrSeries==round(nrSeries) && nrSeries>0, 'If defined, nrSeries must be positive integer' )
end

% Fetch tag(s)
if exist('nrSeries','var')
    tags = varargin{end-1};
else
    tags = varargin{end};
end
AssertIsCharOrCellstr(tags);
tags = cellstr(tags);

% Get recursive args : 'dir_regex_1', 'dir_regex_2'
% Other previous args are used to navigate/search for GET_SUBDIR_REGEX
if exist('nrSeries','var')
    recursive_args = varargin(1:end-2);
else
    recursive_args = varargin(1:end-1);
end


%% Extra preparation

% autoIncrement ?
if length(tags)>1
    autoIncrement = 0;
else
    autoIncrement = 1;
end

% checkNr ?
if exist('nrSeries','var')
    checkNr = 1;
else
    if length(tags)>1
        checkNr  = 1;
        nrSeries = length(tags);
    else
        checkNr = 0;
    end
end

if nrSeries == 1
    autoIncrement = 0;
end


%% addSeries to @exam

for ex = 1 : numel(examArray)
    
    % Fetch the directories
    serieList  = get_subdir_regex( examArray(ex).path, recursive_args{:} );
    
    % Be sure to add new series to the serieArray
    lengthSeries = length(examArray(ex).series);
    counter = 0;
    
    if ~isempty(serieList)
        
        % Check if N series are found for N tags.
        if checkNr && ( length(serieList) ~= nrSeries )
            error([
                'Number of input tag/nrSeries differs from number of series found \n'...
                '#%d : %s ' ...
                ], ex, examArray(ex).path)
        end
        
        for ser = 1 : length(serieList)
            counter = counter + 1;
            if autoIncrement
                tag = sprintf('%s_%0.3d',char(tags),counter);
            else
                tag = tags{ser};
            end
            examArray(ex).series(lengthSeries + counter) = serie(serieList{ser}, tag, examArray(ex) );
        end % found dir (== series)
        
    else
        
        % When dirs are not found
        warning([
            'Could not find recursivly any dir corresponding to the regex [ %s] \n'...
            '#%d : %s' ...
            ], sprintf('%s ',recursive_args{:}), ex, examArray(ex).path ) %#ok<SPWRN>
        
        examArray(ex).is_incomplete = 1; % set incomplete flag
        
        % Add empty series, but with pointer to the exam : for diagnostic
        for ser = 1 : length(tags)
            counter = counter + 1;
            examArray(ex).series(lengthSeries + counter)      = serie();
            examArray(ex).series(lengthSeries + counter).tag  = tags{ser};
            examArray(ex).series(lengthSeries + counter).exam = examArray(ex);
        end
        
    end
    
end % exam


end % function
