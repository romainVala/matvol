function [output, not_found]=get_subdir_regex(indir,reg_ex,varargin)

if ~exist('indir'), indir=pwd;end
if ~exist('reg_ex'), reg_ex=('graphically');end

if length(varargin)>0
  output = get_subdir_regex(indir,reg_ex);
  for ka=1:length(varargin)
    output = get_subdir_regex(output,varargin{ka});
  end
  return
end

if ~iscell(indir), indir={indir};end


if ~iscell(reg_ex), reg_ex={reg_ex};end

output={};
not_found={};

for nb_dir=1:length(indir)
  od = dir(indir{nb_dir});
  od = od(3:end);

  %order time
  for kk=1:length(od)
    dirtime(kk) = od(kk).datenum;
  end
  [v,ind]=sort(dirtime);
  od = od(ind);
  
  
  found_sub=0;
  
  for k=1:length(od)
    
    for nb_reg=1:length(reg_ex)      
      if strcmp(reg_ex{nb_reg}(1),'-')
%	reg_ex{nb_reg}(1)=''
	if od(k).isdir & ~isempty(regexp(od(k).name,reg_ex{nb_reg}(2:end)))
	  break
	end
      end
      
      if od(k).isdir & ~isempty(regexp(od(k).name,reg_ex{nb_reg}))
	output{end+1,1} = fullfile(indir{nb_dir},od(k).name,filesep);
	found_sub=1;
	break% (to avoid that 2 reg_ex adds the same dir
      end
      
    end
    
  end
  
  if ~found_sub
    not_found{end+1} = indir{nb_dir};
  end
end
