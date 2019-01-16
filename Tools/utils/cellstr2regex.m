function [ regex ] = cellstr2regex( inputCELLSTR, exactly )
%CELLSTR2REGEX transform all elements in a cellstr into a regex such as :
% regex = (input{1})|(input{2})|....(input{n-1})|(input{n});
%
% Syntax  : [ regex ]     = cellstr2regex( inputCELLSTR )
% Exemple : '(a)|(b)|(c)' = cellstr2regex( {'a' ; 'b' ; 'c'} )
%
% Syntax  : [ regex ]     = cellstr2regex( inputCELLSTR, 1 )
% Exemple : '(^a$)|(^b$)|(^c$)' = cellstr2regex( {'a' ; 'b' ; 'c'} , 1 )

AssertIsCharOrCellstr(inputCELLSTR);
inputCELLSTR = cellstr(inputCELLSTR); % force cellstr

if nargin < 2
    exactly = 0;
end

if numel(inputCELLSTR)==1 % str
    
    if exactly
        regex = ['^' inputCELLSTR{1} '$'];
    else
        regex = inputCELLSTR{1};
    end
    
elseif numel(inputCELLSTR)>1 % cellstr
    
    % Concatenation
    if exactly
        rep = repmat('(^%s$)|',[1 length(inputCELLSTR)]);
    else
        rep = repmat('(%s)|',[1 length(inputCELLSTR)]);
    end
    rep   = rep(1:end-1);
    regex = sprintf(rep,inputCELLSTR{:});
    
else
    error('[%s] : WTF ??', mfilename)
    
end

end % function
