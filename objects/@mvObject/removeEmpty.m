function new_mvArray = removeEmpty( mvArray )
% Flatten dimensions (N-D array to 1-D vector) and remove empty elements

new_mvArray = mvArray(:);
index = ~cellfun( 'isempty' , new_mvArray.getPath );
new_mvArray = new_mvArray(index);

end % function
