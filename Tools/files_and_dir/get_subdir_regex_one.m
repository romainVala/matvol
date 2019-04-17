function [output no_reg no_dir no_ind ] = get_subdir_regex_one(indir,reg_ex,varargin)

wanted_nbdir =1;

if ~isempty(varargin)
    if isnumeric(varargin{end})
        wanted_nbdir = varargin{end};
        varargin(end)='';
    end
end

if length(varargin)>0
    output = get_subdir_regex_one(indir,reg_ex);
    for ka=1:length(varargin)
        output = get_subdir_regex_one(output,varargin{ka});
    end
    return
end


if ~iscell(reg_ex), reg_ex={reg_ex};end
if ~iscell(indir), indir={indir};end

output={};

if length(indir)==1
    indir = repmat(indir,size(reg_ex));
end

if length(reg_ex)==1
    reg_ex = repmat(reg_ex,size(indir));
end

if length(indir)~=length(reg_ex)
    error('you should have one regex for each indi\n')
end

 no_dir ={}; no_reg={}; no_ind=[];
 
for nb_dir=1:length(indir)
    od = dir(indir{nb_dir});
    od = od(3:end);
    
    found=0;
    output{nb_dir,1} = {};

    for k=1:length(od)
        %    for nb_reg=1:length(reg_ex)
                
        if od(k).isdir & ~isempty(regexp(od(k).name,reg_ex{nb_dir}))
            if ~found
                output{nb_dir,1} = fullfile(indir{nb_dir},od(k).name,filesep);
                found=1;
            else
                found = found+1;
            end
        end
        
    end
    if isempty(output{nb_dir})
        fprintf('warning suj %d %s has no %s subdir\n',nb_dir,indir{nb_dir},reg_ex{nb_dir})
        no_dir{end+1} = indir{nb_dir};
        no_reg{end+1} = reg_ex{nb_dir};
        no_ind(end+1) = nb_dir;
    elseif all(repmat(found,size(wanted_nbdir))~=wanted_nbdir)
    
        fprintf('warning suj %d %s has %d  subdir for %s \n',nb_dir,indir{nb_dir},found,reg_ex{nb_dir})
        %tomuch_dir{end+1} = reg_ex{nb_dir};
    end
    
   end
    
end
