function  randomElement = getOne( mvArray )
%GETONE Will pick a random element

idx = randperm(numel(mvArray),1);

randomElement = mvArray(idx);

end % function
