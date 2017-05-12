function do_delete(f,ask)

if ~exist('ask')
 ask=1;
end
%do_delet(f)
%f  a list of cell containing images to be deleted

cf =  char(f);
if isdir(deblank(cf(1,:)))
 ddir=1;
else
 ddir=0;
end

if ask
  fprintf('Are you sure you want to delete those %d files \n',size(cf,1))

  R = input('yes or no\n','s');
else
  R='yes';
end

if strcmp(R,'yes')
  for k=1:size(cf,1)
    if ddir
      cmd = (['rm -rf ', deblank(cf(k,:))]);
      unix(cmd);
    else
      delete(deblank(cf(k,:)));
    end
  end
  fprintf(' done \n');
else
  fprintf('nothing done \n');
end

