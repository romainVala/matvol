function explore( obj )
% EXPLORE method displays the content of the object

for idx = 1 : numel(obj)
%     cprintf('[0.1,0.5,0]','    +++ %s -> %s \n', obj(idx).tag, obj(idx).name)
    fprintf('    +++ %s -> %s \n', obj(idx).tag, obj(idx).name)
    obj(idx).volumes.explore;
    obj(idx).stim.explore;
end

end % function
