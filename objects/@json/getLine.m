function out = getLine( jsonArray , regex, display, format )


%% Check input arguments

assert( ~isempty(regex ) && ischar(regex ),      'regex must be a non-empy char' )

if nargin > 2
    
else
    display = 1;
end

if nargin > 3
    assert( ~isempty(format) && ischar(format), 'format must be a non-empy char' )
else
    format = '';
end


%% Fetch

out = cell(size(jsonArray));

for vol = 1 : numel(jsonArray)
    
    if ~isempty(jsonArray(vol).path)
        
        if size(jsonArray(vol).path,1) == 1
            
            multiple_level = 0;
            
            out{vol} = fetch_content(deblank(jsonArray(vol).path), regex, display);
            
        else
            
            multiple_level = 1;
            out_tmp = cell(0);
            
            for j = 1 : size(jsonArray(vol).path,1)
                
                result = fetch_content(deblank(jsonArray(vol).path(j,:)), regex, display);
                
                out_tmp{end+1,1} = result; %#ok<AGROW>
                
            end % j
            
            out_tmp_num = cellfun(@str2double, out_tmp);
            if ~all(isnan(out_tmp_num(:)))
                out{vol} = out_tmp_num;
            else
                out{vol} = out_tmp;
            end
            
        end
        
    end
    
end % vol


%% Convert output type

if multiple_level == 0
    
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
    
else
    % pass
end

end % function

function result = fetch_content(filename,regex, display)

if display
    fprintf('%s : ', deblank(filename))
end

% Read the file
content = get_file_content_as_char( deblank(filename) );

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
        result = res(2:end-1);
    else
        result = res;
    end
    
    if display
        fprintf('%s', line);
    end
    
else
    result = [];
end

if display
    fprintf('\n');
end

end % function
