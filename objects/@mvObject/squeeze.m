function new_mvArray = squeeze( mvArray )
% Squeeze dimensions (remove dimensions when it has only 1 element)

siz = size(mvArray);
siz(siz==1) = [];
siz = [siz ones(1,2-length(siz))];
new_mvArray = reshape(mvArray,siz);

end % function
