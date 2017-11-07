function explore( obj )
% EXPLORE method displays the content of the object

for idx = 1 : numel(obj)
    
    %     cprintf('blue','        --- %s -> %s \n', obj(idx).tag, obj(idx).name)
    
    for n = 1 : size(obj(idx).name,1)
        
        if n == 1
            fprintf('        ... %s -> %s \n', obj(idx).tag, obj(idx).name(n,:))
        else
            fprintf('        ...       %s \n',               obj(idx).name(n,:))
        end
        
    end % name
    
end % obj

end % function
