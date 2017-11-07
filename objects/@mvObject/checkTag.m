function [ flag ] = checkTag( mvArray, tag )
%CHECKTAG tells you if the object array already contains the tag

% Fetch all tags into a signle cellstr
allTags = cellstr(char(mvArray.tag));

% Concatenate if tag is a cellstr
tags = cellstr2regex(tag);

% Input tag exists in all tags of the array ?
allFlags = cell2mat(regexp(allTags,tags,'once'));
if ~isempty(allFlags) % yes
    flag = 1;
else % no
    flag = 0;
end

end % function
