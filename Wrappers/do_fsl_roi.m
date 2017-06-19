function fo = do_fsl_roi(f,name,ind_start,num)

if ~exist('ind_start')
    ind_start=0;
end
if ~exist('num')
    num=1;
end

f=cellstr(char(f));

if ischar(name)
    [pp ff] = get_parent_path(f);
    fo = addsuffixtofilenames(pp,['/' name]);
elseif iscell(name)
    fo = name;
end

for k=1:length(f)
    
    cmd = sprintf('fslroi %s %s ',f{k},fo{k});
    
    for nbind=1:length(ind_start)
        cmd = sprintf('%s %d %d',cmd,ind_start(nbind),num(nbind));
    end
    
    unix(cmd);
    
end
