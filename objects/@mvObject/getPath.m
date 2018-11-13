function path = getPath( mvArray )
%GETPATH output is a cell of mvArray(i).path, with the same dimension as mvArray
% exemple : path{x,y,x} = mvArray{x,y,z}.path

path = cell(size(mvArray));

for p = 1 : numel(mvArray)
    path{p} = mvArray(p).path;
end

end % function
