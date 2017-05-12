function fo = unzip_volume(f)

f = cellstr(char(f));

for i=1:length(f)

  if strcmp(f{i}(end-1:end),'gz')
    cmd = sprintf('gunzip -f %s',f{i});

    fo{i} = f{i}(1:end-3);
  
    unix(cmd);
  else
    fo{i} = f{i};
  end
  
end
