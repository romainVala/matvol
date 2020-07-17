function result = isGZ( volumeArray )
% Check if the volume has .gz in the end

path = volumeArray.getPath;

res = regexp(path,'\.gz$');
result = ~cellfun('isempty',res);

end % function
