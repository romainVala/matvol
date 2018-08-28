function gedit( jsonArray )
% GEDIT opens all files in gedit

cmd = jsonArray.path2line;
cmd = sprintf('gedit %s', cmd);
cmd = sprintf('%s &', cmd);
unix( cmd );

end % function
