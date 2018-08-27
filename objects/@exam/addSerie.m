function varargout = addSerie( examArray, varargin)
% General syntax : jobInput = examArray.addSerie( 'dir_regex_1', 'dir_regex_2', ... , {'tag_1', 'tag_2', ...}, N );
%
% Example :
%
% examArray.addSerie( 'PA$', {'run1', 'run2'} );
% is equivalent to
% examArray.addSerie( 'PA$', {'run1', 'run2'}, 2 );
%
% examArray.addSerie( 'PA$', 'run' );
% will auto increment run_001, run_002, ... for all dir_found
% it differes from :
% examArray.addSerie( 'PA$', 'run', 2 );
% will auto increment run_001, run_002, but error if nr_dir_found ~= 2
%
% jobInput is the output examArray.getSerie("all tags combined").toJob
%


%% Check inputs

% Need at least dir_regex + tag
assert( length(varargin)>=2 , '[%s]: requires at least 2 input arguments dir_regex + tag', mfilename)

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
        checkNr  = 0;
        nrSeries = [];
    end
end

if nrSeries == 1
    autoIncrement = 0;
end


%% addSerie to @exam

for ex = 1 : numel(examArray)
    
    % Remove duplicates
    if examArray(ex).cfg.remove_duplicates
        
        if examArray(ex).serie.checkTag(tags)
            examArray(ex).serie = examArray(ex).serie.removeTag(tags);
        end
        
    else
        
        % Allow duplicate ?
        if examArray(ex).cfg.allow_duplicate % yes
            % pass
        else% no
            if examArray(ex).serie.checkTag(tags)
                continue
            end
        end
        
    end
    
    % Fetch the directories
    serieList  = get_subdir_regex( examArray(ex).path, recursive_args{:} );
    
    % Be sure to add new series to the serieArray
    lengthSeries = length(examArray(ex).serie);
    counter      = 0;
    
    % Non-empy list ?
    if ~isempty(serieList)
        
        % Check if N series are found for N tags.
        if checkNr && ( length(serieList) ~= nrSeries )
            examArray(ex).is_incomplete = 1; % set incomplete flag
            warning([
                'Found %d/%d series with recursive_regex_path [ %s] \n'...
                '#%d : %s ' ...
                ], length(serieList), nrSeries, sprintf('%s ', recursive_args{:}), ...
                ex, examArray(ex).path)
        else
            
            % Add the series
            for ser = 1 : length(serieList)
                counter = counter + 1;
                if autoIncrement
                    tag  = sprintf('%s_%0.3d',char(tags),counter);
                    nick = char(tags);
                    inc  = counter;
                else
                    tag  = tags{ser};
                    nick = tags{ser};
                    inc  = [];
                end
                examArray(ex).serie(lengthSeries + counter) = serie(serieList{ser}, tag, nick, inc, examArray(ex) );
            end % found dir (== series)
            
        end

    else
        
        % When dirs are not found
        warning([
            'Dir not found for recursive_regex_path [ %s] \n'...
            '#%d : %s' ...
            ], sprintf('%s ',recursive_args{:}), ...
            ex, examArray(ex).path ) %#ok<SPWRN>
        
        examArray(ex).is_incomplete = 1; % set incomplete flag
        
        % Add empty series, but with pointer to the exam : for diagnostic
        for ser = 1 : length(tags)
            counter = counter + 1;
            examArray(ex).serie(lengthSeries + counter)      = serie();
            examArray(ex).serie(lengthSeries + counter).tag  = tags{ser};
            examArray(ex).serie(lengthSeries + counter).exam = examArray(ex);
        end
        
    end
    
end % exam


%% Output

if nargout > 0
    
    varargout{1} = examArray.getSerie( cellstr2regex(tags) ).toJob;
    
end


end % function
