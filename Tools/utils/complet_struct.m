function newStruct = complet_struct(inputStruct,baseStruct)
% COMPLET_STRUCT will complete the inputStruct with fields from baseStruct
% if they are missing

fields = fieldnames(baseStruct);

newStruct = inputStruct;

for f = 1 : length(fields)
  if ~isfield(inputStruct,fields{f})
    newStruct.(fields{f}) = baseStruct.(fields{f});
  end
  
end

end % function
