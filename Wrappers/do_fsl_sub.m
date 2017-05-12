function out = do_fsl_sub(fo,outname)
%function out = do_fsl_add(fo,outname)
%fo is either a cell or a matrix of char
%outname is the name of the fo volumes sum
%

if iscell(outname)
 if length(fo)~=length(outname)
   error('the 2 cell input must have the same lenght')
 end
 
   
  for k=1:length(outname)
    out{k} = do_fsl_sub(fo{k},outname{k});
  end
  return
end


fo = cellstr(char(fo));

cmd = sprintf('fslmaths %s',fo{1});

for k=2:length(fo)
  cmd = sprintf('%s -sub %s',cmd,fo{k});
end

cmd = sprintf('%s %s',cmd,outname);


fprintf('writing %s \n',outname)
%fprintf('writing %s \n%s\n',outname,cmd)
unix(cmd);

out = [outname '.nii.gz'];
