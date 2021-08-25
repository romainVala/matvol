function str = path2line( mvArray )
% PATH2LINE conctatenate all objects path into a char, whitespace separator

p = {mvArray.path};
str = sprintf('%s ', p{:});

end % function
