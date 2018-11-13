function  randomElement = getOne( mvArray )

idx = randperm(numel(mvArray),1);

randomElement = mvArray(idx);

end % function
