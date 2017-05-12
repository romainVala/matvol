function o=get_subdir_regex_multi(indir,reg_ex,varargin)


if length(varargin)>0
fprintf('Check it  !! not tested c rrr')
return
end


for ki=1:length(indir)
    o{ki} = get_subdir_regex(indir(ki),reg_ex);
end

