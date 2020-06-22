function result = has_nonGZ( volumeArray )
% Check if a nonGZ volume exists

result = ones(size(volumeArray));

% Remove non GZ files of the future checks
isGZ = volumeArray.isGZ;
volumeArray = volumeArray(isGZ);

% Check
path = volumeArray.getPath;
nonGZ_path = regexprep(path,'\.gz$','');
for p = 1 : numel(path)
    result(p) = exist(nonGZ_path{p},'file')~=0;
end

end % function
