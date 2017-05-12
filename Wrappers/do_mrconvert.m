function fo = do_mrconvert(src,prefixl)

if ~exist('prefix')
    prefix='mr_';
end


for k=1:length(src)
    ff = cellstr(src{k});
    ffo = addprefixtofilenames(ff,prefix);
    ffo = change_file_extension(ffo,'.nii');
    
    for kk=1:length(ff)
        if ~exist(ffo{kk},'file')
            cmd = sprintf('mrconvert %s %s',ff{kk},ffo{kk});
            unix(cmd);
        end
        
    end
    fo{k} = char(ffo);
end
