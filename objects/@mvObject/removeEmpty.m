function new_mvArray = removeEmpty( mvArray )

new_mvArray = mvArray(:);
index = ~cellfun( @isempty , new_mvArray.getPath );
new_mvArray = new_mvArray(index);

end % function
