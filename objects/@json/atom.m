function atom( jsonArray )
% ATOM opens all files in Atom

cmd = jsonArray.path2line;
cmd = sprintf('atom %s', cmd);
cmd = sprintf('%s &', cmd);
unix( cmd );

end % function
