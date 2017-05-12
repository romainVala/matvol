function fo = do_fsl_find_thebiggest(f,fos)



for k=1:length(f)
    
    ff = cellstr(char(f(k)));
    [p aa] = fileparts(ff{1})
    
    if ~exist('fos','var')
        fo{k} = fullfile(p,'the_biggest');
    else
        fo(k) = fos(k);
    end
    
    cmd = sprintf('find_the_biggest ');
    for kk =1:length(ff)
        cmd = sprintf('%s %s',cmd,ff{kk});
    end
    cmd = sprintf('%s %s',cmd,fo{k});
    
    unix(cmd);
    
end
