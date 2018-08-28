function more( jsonArray )
% MORE opens all files in matlab terminal

assert( numel(jsonArray)==1, 'more can only open 1 file in the terminal, because it is interactive' )

cmd = jsonArray.path;
cmd = sprintf('more %s', cmd);
unix( cmd );

end % function
