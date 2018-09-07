function AssertIsCharOrCellstr( input )

assert( ( ischar(input) || iscellstr(input) ) && ~isempty(input) , '%s must be a non-empty char or cellstr', inputname(1) )

end % function
