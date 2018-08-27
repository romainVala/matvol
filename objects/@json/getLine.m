function out = getLine( volumeArray , regex )

out = cell(size(volumeArray));

for vol = 1 : numel(volumeArray)
    
    if ~isempty(volumeArray(vol).path)
        
        fprintf('%s : ', volumeArray(vol).path)
        
        % Read the file
        fid = fopen(volumeArray(vol).path, 'rt');
        if fid == -1
            error('file cannot be opened : %s', volumeArray(vol).path)
        end
        content = fread(fid, '*char')'; % read the whole file as a single char
        fclose(fid);
        
        %         token = regexp(content, [ '"' 'EchoTime' '": "([A-Za-z0-9-_,;]+)",' ],'tokens')
        %         token = regexp(content, [ '"' 'EchoTime' '": (([-e.]|\d)+),' ],'tokens')
        
        % Fetch the line content
        start = regexp(content           , regex, 'once');
        stop  = regexp(content(start:end), ','  , 'once');
        line = content(start:start+stop);
        token = regexp(line, ': (.*),','tokens');
        
        if ~isempty(token)
            
            res = token{1}{1};
            
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

% Try to convert to numeric
tmp = cellfun(@str2double, out);
if ~all(isnan(tmp(:)))
    out = tmp;
end

end % function
