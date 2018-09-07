function [ regex ] = cellstr2regex( inputCELLSTR )
%CELLSTR2REGEX transform all elements in a cellstr into a regex such as :
% regex = (input{1})|(input{2})|....(input{n-1})|(input{n});
%
% Syntax  : [ regex ]     = cellstr2regex( inputCELLSTR )
% Exemple : '(a)|(b)|(c)' = cellstr2regex( {'a' ; 'b' ; 'c'} )


AssertIsCharOrCellstr(inputCELLSTR);
inputCELLSTR = cellstr(inputCELLSTR); % force cellstr

if numel(inputCELLSTR)==1 % str
    regex = inputCELLSTR{1};
    
elseif numel(inputCELLSTR)>1 % cellstr
    
    % Concatenation
    rep  = repmat('(%s)|',[1 length(inputCELLSTR)]);
    rep  = rep(1:end-1);
    regex = sprintf(rep,inputCELLSTR{:});
    
else
    error('[%s] : WTF ??', mfilename)
    
end

end % function
