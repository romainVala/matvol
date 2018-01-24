function [ SPMstruct ] = load( modelArray )
%LOAD

for idx = 1 : numel(modelArray)
    
    s = load(modelArray(idx).path, 'SPM');
    SPMstruct = s.SPM;
    
end % for all objects in modelArray

end % function
