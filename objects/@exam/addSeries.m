function addSeries( examArray, varargin)
% Syntax  : examArray.addSeries( 'regex_1', 'regex_2', ... , {'tag_1', 'tag_2', ...} );
% Example : examArray.addSeries( 'PA$', {'run1', 'run2'} );


%% Check inputs

AssertIsExamArray(examArray);


%% addSeries to @exam

for ex = 1 : numel(examArray)
    
    % Last argument is always the cell of tags
    tags = cellstr(varargin{end});
    AssertIsCharOrCellstr(tags);
    
    % Other previous args are used to navigate/search for GET_SUBDIR_REGEX
    recursive_args = varargin(1:end-1);
    
    % Fetch the directories
    serieList  = get_subdir_regex( examArray(ex).path, recursive_args{:} );
    
    % Be sure to add new series to the serieArray
    nrSeries = length(examArray(ex).series);
    counter = 0;
    
    if ~isempty(serieList)
        
        % Check if N series are found for N tags.
        if length(serieList) ~= length(tags)
            error([
                'Number of input tags differs from number of series found \n'...
                '#%d : %s ' ...
                ], ex, examArray(ex).path)
        end
        
        for ser = 1 : length(tags)
            counter = counter + 1;
            examArray(ex).series(nrSeries + counter) = serie(serieList{ser}, tags{ser}, examArray(ex) );
        end
        
    else
        
        % When series are not found
        warning([
            'Could not find recursivly any dir corresponding to the regex [ %s] \n'...
            '#%d : %s' ...
            ], sprintf('%s ',recursive_args{:}), ex, examArray(ex).path ) %#ok<SPWRN>
        
        % Add empty series, but with pointer to the exam : for diagnostic
        for ser = 1 : length(tags)
            counter = counter + 1;
            examArray(ex).series(nrSeries + counter)      = serie();
            examArray(ex).series(nrSeries + counter).tag  = tags{ser};
            examArray(ex).series(nrSeries + counter).exam = examArray(ex);
        end
        
    end
    
end % exam


end % function
