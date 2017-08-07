function explore( obj )
% EXPLORE method displays the content of the object

for idx = 1 : numel(obj)
%     cprintf('blue','        --- %s -> %s \n', obj(idx).tag, obj(idx).name)
    fprintf('        --- %s -> %s \n', obj(idx).tag, obj(idx).name)
end

end % function
