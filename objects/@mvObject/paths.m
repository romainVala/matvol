function varargout = paths( matvolObjArray )
% PATHS prints all paths of the object or rethrow them in the output variable
% Exemple : matvolObjArray.paths => print
% Exemple : p = matvolObjArray.paths => rethrow in the output variable

p = char(matvolObjArray.path);

if nargout > 0
    varargout{1} = p;
else
    disp(p)
end

end % function
