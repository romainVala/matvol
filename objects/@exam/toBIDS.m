function [ job , error_log ] = toBIDS( examArray , bidsDir , par )
%TOBIDS uses examArray to make BIDS architecure : http://bids.neuroimaging.io/
%
% Syntax : [ job , error_log ] = examArray.toBIDS( bidsDir , par );
%
% See also exam2bids exam

if nargin < 2
    error('bidsDir is required')
end

if nargin < 3
    par='';
end

[ job , error_log ] = exam2bids( examArray , bidsDir , par );

end % function
