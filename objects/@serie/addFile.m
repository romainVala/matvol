function varargout = addFile( serieArray, target, varargin )
% General syntax : jobInput = serieArray.add<target>( 'dir_regex_1', 'dir_regex_2', ... , 'tag', N );
%
% Find all files available, regardlesss of how many they are :
% Syntax  : serieArray.add<target>( 'file_regex', 'tag' )
% Example : serieArray.add<target>( '^f.*nii'   , 'f'   )
% Find exactly nTarget, or return an error :
% Syntax  : serieArray.add<target>( 'file_regex'       , 'tag'        , nTarget )
% Example : serieArray.add<target>( '^c[123456].*nii'  , 'compartment', 6         )
%
% If the first subdir regex is 'root', override the search & check, and add the volume as a fullpath contained in 'file_regex'
%
% If needed, the output is serieArray.getVolume(['^' tag '$']).toJob()
%


%% Check inputs

% Need at least dir_regex + tag
assert( length(varargin)>=2 , '[%s]: requires at least 2 input arguments dir_regex + tag', mfilename)

% nTarget defined ?
if isnumeric( varargin{end} )
    nTarget = varargin{end};
    assert( nTarget==round(nTarget) && nTarget>0, 'If defined, nTarget must be positive integer' )
else
    nTarget = [];
end

% Get recursive args : 'dir_regex_1', 'dir_regex_2', ..., 'tag'
% Other previous args are used to navigate/search for GET_SUBDIR_REGEX
if ~isempty(nTarget)
    recursive_args = varargin(1:end-1);
else
    recursive_args = varargin;
end

% Get content of recursive args
if     length(recursive_args) == 2
    file_regex = recursive_args{1};
    tag        = recursive_args{2};
    
elseif length(recursive_args) >= 2
    subdirs    = recursive_args(1:end-2);
    file_regex = recursive_args{  end-1};
    tag        = recursive_args{  end  };
    
else
    error('?')
    
end

% Check the inputs type & non-emptiness

% file_regex
if ischar(file_regex)
    assert( ~isempty(file_regex), 'file_regex must be non-empty', file_regex )
elseif iscellstr(file_regex)
    file_regex = cellstr2regex(file_regex); % this will also performs the check "non-empty"
else
    error('file_regex must be a non-empy char or cellstr')
end

% tag
if ischar(tag)
    assert( ~isempty(tag), 'tag must be non-empty', tag )
else
    error('reg must be a non-empy char')
end

% subdirs
if exist('subdirs','var')
    AssertIsCharOrCellstr(subdirs) % this will also performs the check "non-empty"
    subdirs = cellstr(subdirs);
end

par.verbose = 0;


%% add<ClassName> to @serie

for ser = 1 : numel(serieArray)
    
    [exam_idx,serie_idx] = ind2sub(size(serieArray),ser);
    
    if ~isempty(serieArray(ser).path)
        
        % Remove duplicates
        if serieArray(ser).cfg.remove_duplicates
            
            if serieArray(ser).(target).checkTag(tag)
                serieArray(ser).(target) = serieArray(ser).(target).removeTag(tag);
            end
            
        else
            
            % Allow duplicate ?
            if serieArray(ser).cfg.allow_duplicate % yes
                % pass
            else% no
                if serieArray(ser).(target).checkTag(tag)
                    continue
                end
            end
            
        end
        
        % Fetch files
        if exist('subdirs','var')
            if length(subdirs)==1 && strcmp(subdirs{1},'root')     % define manually the path of the object
                target_found = file_regex;
                file_path = [fileparts(file_regex) filesep];       % be sure to have a / in the end of the path
                sub = strrep(file_path, serieArray(ser).path, ''); % remove / at the end to save a clean subdir variable
                if ~isempty(sub) && strcmp(sub(end),filesep), sub(end) = []; end
            elseif length(subdirs)==1 && strcmp(subdirs{1},'')     % dynamic adding,    no subdir
                target_found = char(get_subdir_regex_files( serieArray(ser).path, file_regex, par ));
                sub = '';
            else                                                   % dynamic adding, using subdir(s)
                subdir_found = get_subdir_regex( serieArray(ser).path, subdirs{:} );
                target_found = char(get_subdir_regex_files( subdir_found, file_regex, par ));
                sub = char(fullfile(subdirs{:}));
            end
        else
            target_found = char(get_subdir_regex_files( serieArray(ser).path, file_regex, par ));
            sub = '';
        end
        
        if ~isempty(target_found) % file found
            
            % need a specific number of (target)s ?
            if ~isempty(nTarget) % yes, so check it
                
                if size(target_found,1) == nTarget
                    
                    % File found, so add it
                    serieArray(ser).(target)(end + 1) = feval(target, target_found, tag, serieArray(ser).exam , serieArray(ser), sub);
                    
                else
                    
                    if exist('subdirs','var')
                        
                        all_regex = [subdirs {tag}];
                        
                        % When targets found are not exactly nTarget
                        warning([
                            'Found %d/%d %s with the regex [ %s] \n'...
                            '#[%d %d] : %s ' ...
                            ], size(target_found,1), nTarget, target, sprintf('%s ',all_regex{:}), ...
                            exam_idx, serie_idx, serieArray(ser).path )
                        
                    else
                        
                        % When volumes found are not exactly nTarget
                        warning([
                            'Found %d/%d %s with the regex [ %s ] \n'...
                            '#[%d %d] : %s ' ...
                            ], size(target_found,1), nTarget, target, file_regex, ...
                            exam_idx, serie_idx, serieArray(ser).path )
                        
                    end
                    
                    serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
                    
                end
                
            else % no, so the number of files foud does not matter
                
                % File found, so add it
                serieArray(ser).(target)(end + 1) = feval(target, target_found, tag, serieArray(ser).exam , serieArray(ser), sub);
                
            end
            
        else % no file found
            
            if exist('subdirs','var')
                
                all_regex = [subdirs {tag}];
                
                % When targets are not found BECAUSE of incorrect recursive path
                warning([
                    'Found 0 files with recursive regex [ %s] \n'...
                    '#[%d %d] : %s ' ...
                    ],  sprintf('%s ',all_regex{:})...
                    , exam_idx, serie_idx, serieArray(ser).path ) %#ok<SPWRN>
                
            else
                
                % When targets are not found at all
                warning([
                    'Found 0 files with regex [ %s ] \n'...
                    '#[%d %d] : %s ' ...
                    ], file_regex, exam_idx, serie_idx, serieArray(ser).path )
                
            end
            
            serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
            
        end
        
    else % empty serie
        
        %         warning([
        %             'Empty serie : cannot add target \n'...
        %             '#[%d %d] tag=%s \n' ...
        %             '%s' ...
        %             ], exam_idx, serie_idx, serieArray(ser).tag, serieArray(ser).exam.path )
        %
        %         serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
        
    end
    
end % serie


%% Output

if nargout > 0
    varargout{1} = serieArray.getFile(target,['^' tag '$']).toJob;
end


end % function
