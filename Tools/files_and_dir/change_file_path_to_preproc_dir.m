function off = change_file_path_to_preproc_dir(ff,par)

if isstr(ff),
  ff={ff};
end

preproc_dir = par.preproc_subdir;


for nbser = 1:length(ff)
  
  cff = ff{nbser};
  
  [p f e] = fileparts(cff(1,:));
      
  dest_dir  = fullfile(p,preproc_dir);

  if ~exist (dest_dir)
    mkdir(p,preproc_dir)
    if strcmp(spm_platform('filesys'),'win')

      for nbvol = 1:size(cff,1)
	[p f e] = fileparts(deblank(cff(nbvol,:)));
	coff(nbvol,:) = fullfile(p,preproc_dir,[f e]);
	copyfile(fullfile(p,[f,'.*']) ,dest_dir);
      end
      
    else
      for nbvol = 1:size(cff,1)
	[p f e] = fileparts(deblank(cff(nbvol,:)));
	coff(nbvol,:) = fullfile(p,preproc_dir,[f e]);
	cmd = [' cp ', fullfile(p,[f,'.*']) , ' ',dest_dir];
	
	if isfield(par,'link_for_copy')
	  cmd = [' ln -s ', fullfile(p,[f,'.*']) , ' ',dest_dir];
	  %fprintf('warning no cp ln -s\n')    

	else
	  cmd = [' cp ', fullfile(p,[f,'.*']) , ' ',dest_dir];
	end
	
	unix(cmd)
      end
    end
    
  else  
    warning('hmmmm, it should not happen')
    for nbvol = 1:size(cff,1)
      [p f e] = fileparts(cff(nbvol,:));
      coff(nbvol,:) = fullfile(p,preproc_dir,[f e]);
    end 
  end
  
  off{nbser} = coff;
  coff='';
end
