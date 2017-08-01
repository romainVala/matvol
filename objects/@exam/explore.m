function explore( obj )
% EXPLORE method displays the content of the object

for idx = 1 : numel(obj)
    fprintf(' + idx    = %d \n',idx)
    fprintf(' + name   = %s \n',obj(idx).name)
    fprintf(' + path   = %s \n',obj(idx).path)
    fprintf(' + series \n')
    obj(idx).series.explore;
    
end

end % function
