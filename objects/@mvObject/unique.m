function [C,IA,IC] = unique( in_mvArray )

in_path = in_mvArray.getPath;

[~,IA,IC] = unique(in_path,'stable');

C = in_mvArray(IA);

end % function
