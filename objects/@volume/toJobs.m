function [ pathArray ] = toJobs( volumeArray )
% TOJOBS fetches volumeArray.path, just as would do [ get_subdir_regex_multi ]

AssertIsVolumeArray(volumeArray)

pathArray = cell(size(volumeArray,1),1);

for idx = 1:size(volumeArray,1)
    
    pathArray{idx} = char(volumeArray(idx,:).path);
    
    % to simulate the output of get_subdir_regex_multi
    if isempty(char(volumeArray(idx,:).path))
        pathArray{idx} = '';
    end
    
end

end % function
