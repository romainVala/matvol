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
%
%
% jobInput is the output serieArray.getStim(['^' tag '$']).toJob
%


%% Check inputs

assert( ischar(stimPath) && ~isempty(stimPath) , 'stimPath must be a non-empty char' )
assert( ischar(regex    ) && ~isempty(regex  ) , 'regex must be a non-empty char'    )
assert( ischar(tag      ) && ~isempty(tag    ) , 'tag must be a non-empty char'      )

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
    
    % Fetch files
    stim_found = char(get_subdir_regex_files( where, regex, par ));
    
    if ~isempty(stim_found) % file found
        
        if size(stim_found,1) == 1
            
            % File found
            serieArray(ser).stim(end + 1) = stim(char(stim_found), tag, serieArray(ser).exam , serieArray(ser));
            
        else
            
            warning([
                'Found %d/1 stim files with regex [ %s ] \n'...
                '#[%d %d] : %s ' ...
                ], size(stim_found,1), regex, ...
                exam_idx, serie_idx, where )
            
            serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
            
        end
        
    else % no file found
        
        %         % When stim are not found at all
        %         warning([
        %             'Found 0 files with regex [ %s ] \n'...
        %             '#[%d %d] : %s ' ...
        %             ], regex, exam_idx, serie_idx, where )
        %
        %         serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
        
    end
    
end % serie


%% Output

if nargout > 0
    varargout{1} = serieArray.getStim(['^' tag '$']).toJob;
end


end % function
