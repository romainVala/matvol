function change_name( obj ,newname)
% change exam name with a cell list of newname

for idx = 1 : numel(obj)
    obj(idx).name = newname{idx};
end

end % function
