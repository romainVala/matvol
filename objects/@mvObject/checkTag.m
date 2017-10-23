function [ flag ] = checkTag( mvArray, tag )
%CHECKTAG tells you if the object array already contains the tag

% Fetch all tags into a signle cellstr
allTags = cellstr(char(mvArray.tag));

% Contenate if multiple tags
if iscellstr(tag) && numel(tag)>1
    rep  = repmat('%s|',[1 length(tag)]);
    rep  = rep(1:end-1);
    tags = sprintf(['(' rep ')'],tag{:});
else
    tags = tag;
end

% Input tag exists in all tags of the array ?
allFlags = cell2mat(regexp(allTags,tags,'once'));
if ~isempty(allFlags) % yes
    flag = 1;
else % no
    flag = 0;
end

end % function
