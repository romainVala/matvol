function [ newArray ] = removeTag( mvArray, tag )
%REMOVETAG removes all objects from the array according to the tag (regex)

if isempty(mvArray)
    newArray = mvArray;
    return
end

% Fetch all tags into a signle cellstr
allTags = cellstr(char(mvArray.tag));

% Concatenate if tag is a cellstr
tags = cellstr2regex(tag);

% Input tag exists in all tags of the array ?
result = regexp(allTags,tags,'once');
result = cellfun(@isempty,result);

% Only accept (== keep) the non-matching tags
newArray = mvArray(result);

end % function
