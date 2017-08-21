function varargout = print( matvolObjArray )
% PRINT prints all paths of the object or rethrow them in the output variable
% Exemple : matvolObjArray.print => print in command window
% Exemple : p = matvolObjArray.print => rethrow in the output variable

mvOA = shiftdim(matvolObjArray,1); % need to shift dimensions to have the series/volumes displayed in meaningful order.
p = char(mvOA.path);

if nargout > 0
    varargout{1} = p;
else
    disp(p)
end

end % function
