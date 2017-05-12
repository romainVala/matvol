function mrview(f)

f=cellstr(char(f));

cmd='mrview2';
%cmd='fslview';

for k=1:length(f)
    cmd = sprintf('%s %s',cmd,f{k});
end

cmd = sprintf('%s &',cmd)


unix(cmd)

