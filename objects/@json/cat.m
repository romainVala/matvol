function cat( jsonArray )
% CAT concatenate files and print them in the terminal

cmd = jsonArray.path2line;
cmd = sprintf('cat %s', cmd);
unix( cmd );

end % function
