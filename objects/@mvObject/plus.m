function [ out ] = plus( mvArray_1, mvArray_2 )
%PLUS operator
%
% Syntax : newArray = mvArray_1 + mvArray_2
%

assert( isa(mvArray_2,'mvObject') , 'can only use @mvObject for this operation')

assert( strcmp(class(mvArray_1),class(mvArray_2)) , 'can only use the same object for this operation' )

out = [mvArray_1 ; mvArray_2];

end % function
