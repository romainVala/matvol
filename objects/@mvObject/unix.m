function unix( mvArray, cmd )
%L Main routine for all unix commands, such as ls, ll, pwd, applied on the self.path
% Syntax : l('ls')   l('ll')   l('ltr')

for idx = 1 : numel(mvArray)
    
    if ~isempty(mvArray(idx).path)
        
        for l = size(mvArray(idx).path,1)
            
            if exist( mvArray(idx).path , 'dir' )
                unix([cmd ' ' mvArray(idx).path(l,:)]);
                
            else
                unix([cmd ' ' get_parent_path(mvArray(idx).path(l,:))]);
                
            end
            
        end
        
    end
    
end % for all objects in mvArray

end % function
