function [ out ] = minus( mvArray_1, mvArray_2 )
%MINUS operator
%
% Syntax : newArray = mvArray_1 - mvArray_2
%
% This operatior will remove the objects in mvArray_1 corresponding to any tag of mvArray_2
%

assert( isa(mvArray_2,'mvObject') , 'can only use @mvObject for this operation')

assert( strcmp(class(mvArray_1),class(mvArray_2)) , 'can only use the same object for this operation' )

out = mvArray_1.removeTag( {mvArray_2.tag} );

end % function
