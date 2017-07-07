function explore( obj )

for idx = 1 : numel(obj)
    fprintf(' -- name  = %s \n',obj(idx).name)
    % fprintf(' -- path  = %s \n',obj(idx).path)
    fprintf(' -- tag   = %s \n',obj(idx).tag)
end
fprintf('\n')

end % function
