function [ stimstruct ] = load( stimArray )
%LOAD the variables of the .mat file in the current workspace

stimstruct = cell(numel(stimArray),1);

for idx = 1 : numel(stimArray)
    
    if ~isempty(stimArray(idx).path)
        stimstruct{idx} = load(stimArray(idx).path);
    end
    
end % for all objects in stimArray

end % function
