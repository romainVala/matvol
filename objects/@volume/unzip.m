function unzip( volumeArray, par )
% UNZIP unzip volumes, if needed.

if ~exist('par','var'),par ='';end

if ~isempty(volumeArray)
    unzip_volume(volumeArray.toJob, par);
else
    warning('volumeArray is empty, cannot unzip volumes')
end

volumeArray.removeGZ;

end % function
