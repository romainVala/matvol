function varargout = addStim( serieArray, stimPath, regex, tag, nrStim )
% Find all stim available, regardlesss of how many they are :
%
% Method 1 : If 'stimPath' is a path, the function will look for files located @ [stimPath exam.name]
%            It means the dir located at 'stimPath' must have subdir corresponding to the exam.name
%
% Method 2 : If 'stimPath' is not a path, the function will look for files located @ [exam.name stimPath]
%            It means 'stimPath' is the name a dir located inside exam.name
%
%
% Syntax  : jobInput = serieArray.addStim( 'stimPath'    ,    'regex'     , 'tag'    );
% Example : jobInput = serieArray.addStim( 'path/to/stim', 'MRI_run_1.mat', 'onsets' );
% Find exactly nrStim, or return an error :
% Syntax  : jobInput = serieArray.addStim( 'stimPath'    , 'regex'        , 'tag'   , nrStim  );
% Example : jobInput = serieArray.addStim( 'path/to/stim', 'MRI_run_1.mat', 'onsets', 6       );
%
%
% jobInput is the output serieArray.getStim(['^' tag '$']).toJob
%


%% Check inputs

assert( ischar(stimPath) && ~isempty(stimPath) , 'stimPath must be a non-empty char' )
assert( ischar(regex    ) && ~isempty(regex  ) , 'regex must be a non-empty char'    )
assert( ischar(tag      ) && ~isempty(tag    ) , 'tag must be a non-empty char'      )

if nargin == 5 && ~isempty(nrStim)
    assert( isnumeric(nrStim) && nrStim==round(nrStim) && nrStim>0, 'If defined, nrStim must be positive integer' )
    par.wanted_number_of_file = nrStim;
end
par.verbose = 0;

% Method ?
if exist(stimPath,'dir')
    method = 1;
else
    method = 2;
end


%% addStim to @serie

for ser = 1 : numel(serieArray)
    
    % Remove duplicates
    if serieArray(ser).cfg.remove_duplicates
        
        if serieArray(ser).stim.checkTag(tag)
            serieArray(ser).stim = serieArray(ser).stim.removeTag(tag);
        end
        
    else
        
        % Allow duplicate ?
        if serieArray(ser).cfg.allow_duplicate % yes
            % pass
        else% no
            if serieArray(ser).stim.checkTag(tag)
                continue
            end
        end
        
    end
    
    [exam_idx,serie_idx] = ind2sub(size(serieArray),ser);
    
    % Path to stim dirs = [stimPath serieArray(ser).exam.name] // Method 1
    % Path to stim dirs = [serieArray(ser).exam.path stimPath] // Method 2
    % Fetch this dirs
    switch method
        case 1
            where = get_subdir_regex(stimPath,serieArray(ser).exam.name);
        case 2
            where = get_subdir_regex(serieArray(ser).exam.path,stimPath);
    end
    
    if isempty(where) % Invalid path
        
        switch method
            case 1
                warning([
                    'Invalid path [ %s%s%s ] \n'...
                    '#[%d %d] ' ...
                    ], stimPath, filesep, serieArray(ser).exam.name, exam_idx, serie_idx )
            case 2
                warning([
                    'Invalid path [ %s%s ] \n'...
                    '#[%d %d] ' ...
                    ], serieArray(ser).exam.path, stimPath, exam_idx, serie_idx )
        end
        
        continue
        
    else % Valid path
        where = char(where);
    end
    
    try
        
        % Try to fetch stim file
        stim_found = get_subdir_regex_files(where,regex,par); % error from this function if not found
        
        % File found
        serieArray(ser).stim(end + 1) = stim(char(stim_found), tag, serieArray(ser).exam , serieArray(ser));
        
    catch
        
        if nargin == 5 && ~isempty(nrStim)
            % When stim found are not exactly nrStim
            warning([
                'Could not find exactly %d stim corresponding to the regex [ %s ] \n'...
                '#[%d %d] : %s ' ...
                ], nrStim, regex, exam_idx, serie_idx, where )
        else
            % When stim are not found at all
            warning([
                'Could not find any stim corresponding to the regex [ %s ] \n'...
                '#[%d %d] : %s ' ...
                ], regex, exam_idx, serie_idx, where )
        end
        
        serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
        
    end
    
    
end % serie


%% Output

if nargout > 0
    varargout{1} = serieArray.getStim(['^' tag '$']).toJob;
end


end % function
