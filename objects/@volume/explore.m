function explore( obj )
% EXPLORE method displays the content of the object

for idx = 1 : numel(obj)
    fprintf('        --- tag  = %s \n',obj(idx).tag)
    % fprintf('            path = %s \n',obj(idx).path)
    fprintf('            name = %s \n',obj(idx).name)
    
end

end % function
