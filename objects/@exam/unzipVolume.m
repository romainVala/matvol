function unzipVolume( examArray, par )
%UNZIPVOLUME Unzips all volumes in the examArray

if ~exist('par','var'),par ='';end

% Use the method from unzip
examArray.getVolume.unzip(par)

end % function
