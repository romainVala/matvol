function removeGZ( volumeArray )
% REMOVEGZ removes .gz from each file name inside the volumeArray, if needed.

for vol = 1 : numel(volumeArray)
    
    name = cellstr(volumeArray(vol).name);
    name = regexprep(name,'\.gz$','');
    volumeArray(vol).name = char(name);
    
    path = cellstr(volumeArray(vol).path);
    path = regexprep(path,'\.gz$','');
    volumeArray(vol).path = char(path);
    
end % volume

end % function
