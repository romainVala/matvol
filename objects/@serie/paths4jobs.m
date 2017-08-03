function [ pathArray ] = paths4jobs( serieArray )
% GETPATH fetches serieArray.path, just as would do [ get_subdir_regex_multi ]

AssertIsSerieArray(serieArray)

pathArray = cell(size(serieArray,1),1);

for idx = 1:size(serieArray,1)
    
    pathArray{idx} = {serieArray(idx,:).path};
    
    % to simulate the output of get_subdir_regex_multi
    if isempty(char(serieArray(idx,:).path))
        pathArray{idx} = {};
    end
    
end

end % function
