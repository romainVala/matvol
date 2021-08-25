function [C,IA,IC] = unique( in_mvArray )
% UNIQUE performs 'unique' built-in function on .path field

in_path = in_mvArray.getPath;

[~,IA,IC] = unique(in_path,'stable');

C = in_mvArray(IA);

end % function
