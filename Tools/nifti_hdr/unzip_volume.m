function out = unzip_volume(in)
% UNZIP_VOLUME uses gunzip (linux) to unzip volumes if needed.
% If the target file is not zipped (do not have .gz extension), skip it.


% Ensure the inputs are cellstrings, to avoid dimensions problems
in = cellstr(char(in));

for i=1:length(in)
    
    if strcmp(in{i}(end-1:end),'gz')
        cmd = sprintf('gunzip -f %s',in{i});
        out{i} = in{i}(1:end-3); %#ok<*AGROW>
        unix(cmd);
    else
        out{i} = in{i};
    end
    
end

end % function
