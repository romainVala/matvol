function [ examArray ] = generate_examArray_from_dirList( dirList )

dirList = cellstr(dirList);

for idx = 1 : length(dirList)
    examArray(idx) = exam(dirList{idx}); %#ok<AGROW>
end

end % function
