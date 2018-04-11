function unzip( volumeArray )
% UNZIP unzip volumes, if needed.


if ~isempty(volumeArray)
    unzip_volume(volumeArray.toJob);
else
    warning('volumeArray is empty, cannot unzip volumes')
end

volumeArray.removeGZ;

end % function
