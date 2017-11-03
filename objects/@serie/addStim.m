function varargout = addStim( serieArray, stimPath, regex, tag, nrStim )
% Find all stim available, regardlesss of how many they are :
% Syntax  : jobInput = serieArray.addStim( 'stimPath'    ,    'regex'     , 'tag'    );
% Example : jobInput = serieArray.addStim( 'path/to/stim', 'MRI_run_1.mat', 'onsets' );
% Find exactly nrStim, or return an error :
% Syntax  : jobInput = serieArray.addStim( 'stimPath'    , 'regex'        , 'tag'   , nrStim  );
% Example : jobInput = serieArray.addStim( 'path/to/stim', 'MRI_run_1.mat', 'onsets', 6       );
%
% WARNING : there directory to look for the file will be [stimPath '/' exam.name]
% It means stimPath must have subdir corresponding to the exam.name
%
% jobInput is the output serieArray.getStim(['^' tag '$']).toJob
%


%% Check inputs

AssertIsSerieArray(serieArray);

assert( ischar(stimPath) && ~isempty(stimPath) , 'stimPath must be a non-empty char' )
assert( ischar(regex    ) && ~isempty(regex  ) , 'regex must be a non-empty char'    )
assert( ischar(tag      ) && ~isempty(tag    ) , 'tag must be a non-empty char'      )

if nargin == 5 && ~isempty(nrStim)
    assert( isnumeric(nrStim) && nrStim==round(nrStim) && nrStim>0, 'If defined, nrStim must be positive integer' )
    par.wanted_number_of_file = nrStim;
end
par.verbose = 0;


%% addStim to @serie

for ser = 1 : numel(serieArray)
    
    % Allow duplicate ?
    if serieArray(ser).cfg.allow_duplicate % yes
        % pass
    else% no
        if serieArray(ser).stim.checkTag(tag)
            continue
        end
    end
    
    [exam_idx,serie_idx] = ind2sub(size(serieArray),ser);
    
    where = get_subdir_regex(stimPath,serieArray(ser).exam.name);
    if isempty(where)
        % Invalid path
        warning([
            'Invalid path [ %s%s%s ] \n'...
            '#[%d %d] ' ...
            ], stimPath, filesep, serieArray(ser).exam.name, exam_idx, serie_idx )
        continue
    else
        where = char(where);
    end
    
    try
        
        stim_found = get_subdir_regex_files(where,regex,par); % error from this function if not found
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
