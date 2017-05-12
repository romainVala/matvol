function fo = gzip_volume(f)

if isempty(f)
    return
end

f = cellstr(char(f));

for i=1:length(f)

  if ~strcmp(f{i}(end-1:end),'gz')
    cmd = sprintf('gzip -f %s',f{i});

    fo{i} = [f{i} '.gz'];
  
    unix(cmd);
  else
    fo{i} = f{i};
  end
  
end
