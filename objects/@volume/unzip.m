function unzip( volumeArray )
% UNZIP unzip volumes, if needed.

AssertIsVolumeArray(volumeArray)

if ~isempty(volumeArray)
    unzip_volume(volumeArray.toJob);
else
    warning('volumeArray is empty, cannot unzip volumes')
end

volumeArray.removeGZ;

end % function
