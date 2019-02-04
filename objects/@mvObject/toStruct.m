function structure = toStruct( mvArray )
% TOSTRUCT Export all proporties of the object into a structure, so it can be saved.

ListProperties = properties(mvArray);

structure = struct;

for mv = 1 : numel(mvArray)
    for prop_number = 1:length(ListProperties)
        structure(mv,1).(ListProperties{prop_number}) = mvArray(mv).(ListProperties{prop_number});
    end
end

end % function
