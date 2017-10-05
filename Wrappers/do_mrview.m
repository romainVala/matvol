function mrview(f,fref)
if ~exist('fref','var')
    fref='';
end

f=cellstr(char(f));

cmd='mrviewv';
%cmd='fslview';

for k=1:length(f)
    cmd = sprintf('%s %s',cmd,f{k});
end

if ~isempty(fref)
    fref=char(fref);
cmd = sprintf('%s -overlay.load %s -overlay.opacity 0.3 &',cmd,fref)
else
cmd = sprintf('%s &',cmd)
end

unix(cmd)

