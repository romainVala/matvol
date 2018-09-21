function [ job ] = toBIDS( examArray , bidsDir , par )
%TOBIDS uses examArray to make BIDS architecure : http://bids.neuroimaging.io/
%
% Syntax : [ job ] = examArray.toBIDS( bidsDir , par );
%
% See also exam2bids exam

if nargin < 2
    error('bidsDir is required')
end

if nargin < 3
    par='';
end

[ job ] = exam2bids( examArray , bidsDir , par );

end % function
