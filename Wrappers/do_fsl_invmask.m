function fo = do_fsl_invmask(f,name)

if ~exist('name')
  name='inv_';
end


f=cellstr(char(f));

fo = addprefixtofilenames(f,name);

for k=1:length(f)
  [pp ff] = fileparts(f{k});
  
  cmd = sprintf('fslmaths %s -sub 1 -abs %s',f{k},fo{k});
  unix(cmd);

% cmd = sprintf('fslmaths %s -abs %s',fo{k},fo{k});
%  unix(cmd);

  
end
