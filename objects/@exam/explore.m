function explore( obj )
% EXPLORE method displays the content of the object

for idx = 1 : numel(obj)
    %     cprintf('red','|---idx  = %d \n',idx)
    %     cprintf('red','    name = %s \n',obj(idx).name)
    %     cprintf('red','    path = %s \n',obj(idx).path)
    fprintf('|---idx  = %d \n',idx)
    fprintf('    name = %s \n',obj(idx).name)
    fprintf('    path = %s \n',obj(idx).path)
    obj(idx).serie.explore;
    obj(idx).model.explore;
    fprintf('\n')
end

end % function
