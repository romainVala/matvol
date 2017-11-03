function unzip( volumeArray )
% UNZIP unzip volumes, if needed.

AssertIsVolumeArray(volumeArray)

unzip_volume(volumeArray.toJob);

volumeArray.removeGZ;

end % function
