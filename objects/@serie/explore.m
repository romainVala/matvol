function explore( obj )
% EXPLORE method displays the content of the object

for idx = 1 : numel(obj)
    %     cprintf('[0.1,0.5,0]','    +++ %s -> %s \n', obj(idx).tag, obj(idx).name)
    fprintf('    +++ %s -> %s \n', obj(idx).tag, obj(idx).name)
    obj(idx).volume.explore;
    obj(idx).stim.explore;
    obj(idx).json.explore;
end

end % function
