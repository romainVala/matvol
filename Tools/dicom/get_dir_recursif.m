function F=get_dir_recursif(in_dir,par)

if ~exist('par','var'),par ='';end
defpar.dic_ext='.dic';
par = complet_struct(par,defpar);

F=[];
  
for nbdir =1:size(in_dir,1)
  cur_dir = deblank(in_dir(nbdir,:));
  
  DD = dir(cur_dir);
  DD=DD(3:end);

  for i=1:size(DD,1)

    if ( DD(i).isdir )
      F = [F;get_dir_recursif( fullfile(cur_dir,DD(i).name) ,par)];
    else 
      [pathstr,filename,ext] = fileparts(DD(i).name);
      if ~isempty(ext)
%	if  ~all(ext == '.log') & ~all(ext == '.txt')
    
	if  strcmp(ext,par.dic_ext) 
	  F = [F;{fullfile(cur_dir,'/')}];
	  break
	end
      end
    end
  end
end

  
