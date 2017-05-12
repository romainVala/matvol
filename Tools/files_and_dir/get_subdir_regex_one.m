function o=get_subdir_regex_one(indir,reg_ex,varargin)

if length(varargin)>0
    o = get_subdir_regex_one(indir,reg_ex);
    for ka=1:length(varargin)
        o = get_subdir_regex_one(o,varargin{ka});
    end
    return
end


if ~iscell(reg_ex), reg_ex={reg_ex};end
if ~iscell(indir), indir={indir};end

o={};

if length(indir)==1
    indir = repmat(indir,size(reg_ex));
end

if length(reg_ex)==1
    reg_ex = repmat(reg_ex,size(indir));
end

if length(indir)~=length(reg_ex)
    error('you should have one regex for each indi\n')
end


for nb_dir=1:length(indir)
    od = dir(indir{nb_dir});
    od = od(3:end);
    
    found=0;
    o{nb_dir} = {};

    for k=1:length(od)
        %    for nb_reg=1:length(reg_ex)
                
        if od(k).isdir & ~isempty(regexp(od(k).name,reg_ex{nb_dir}))
            if ~found
                o{nb_dir} = fullfile(indir{nb_dir},od(k).name,filesep);
                found=1;
            else
                found = found+1;
            end
        end
        
    end

    if found>1
    
        fprintf('warning suj %s has %d  subdir for %s \n',indir{nb_dir},found,reg_ex{nb_dir})
    end
    
    if isempty(o{nb_dir})
        fprintf('warning suj %d %s has no %s subdir\n',nb_dir,indir{nb_dir},reg_ex{nb_dir})
    end
    
end
