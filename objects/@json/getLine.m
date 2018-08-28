function out = getLine( jsonArray , regex, format )


%% Check input arguments

assert( ~isempty(regex ) && ischar(regex ),      'regex must be a non-empy char' )

if nargin > 2
    assert( ~isempty(format) && ischar(format), 'format must be a non-empy char' )
else
    format = '';
end


%% Fetch

out = cell(size(jsonArray));

for vol = 1 : numel(jsonArray)
    
    if ~isempty(jsonArray(vol).path)
        
        fprintf('%s : ', jsonArray(vol).path)
        
        % Read the file
        fid = fopen(jsonArray(vol).path, 'rt');
        if fid == -1
            error('file cannot be opened : %s', jsonArray(vol).path)
        end
        content = fread(fid, '*char')'; % read the whole file as a single char
        fclose(fid);
        
        %         token = regexp(content, [ '"' 'EchoTime' '": "([A-Za-z0-9-_,;]+)",' ],'tokens')
        %         token = regexp(content, [ '"' 'EchoTime' '": (([-e.]|\d)+),' ],'tokens')
        
        % Fetch the line content
        start = regexp(content           , regex, 'once');
        stop  = regexp(content(start:end), ','  , 'once');
        line = content(start:start+stop); % extract the value from the line
        token = regexp(line, ': (.*),','tokens');
        
        if ~isempty(token)
            
            res = token{1}{1};
            
            % Remoce " at begining & end
            if strcmp(res(1),'"') && strcmp(res(end),'"')
                out{vol} = res(2:end-1);
            else
                out{vol} = res;
            end
            
            fprintf('%s', line);
            
        end
        
        fprintf('\n');
        
    end
    
end % vol


%% Convert output type

if ~isempty(format)
    
    switch lower(format)
        case { 'double' , 'num' , 'numeric' }
            out = cellfun(@str2double, out);
        case { 'char' , 'string' , 'str' }
            % pass
        otherwise
            error('unrecognized type : %s',format)
    end
    
else
    
    % Try to convert to numeric
    tmp = cellfun(@str2double, out);
    if ~all(isnan(tmp(:)))
        out = tmp;
    end
    
end

end % function
