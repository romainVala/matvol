
for i = 1:length(filelist)
    
    wfiles = [];
    
    for line = 1:size(filelist{i},1)
        [pathstr,name,extension] = fileparts( deblank( filelist{i}(line,:) ) );
        if strcmp(name(1:length(prefix{i})),prefix{i})
            name(1:length(prefix{i}))=[];
        end
        wfiles = strvcat(wfiles, fullfile(pathstr,[ name extension ])); %#ok<*AGROW>
    end
    
    newlist{i} = wfiles;
    
end

if makeitchar
    newlist = char(newlist);
end


end % function
