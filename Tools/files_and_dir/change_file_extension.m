function fo = change_file_extension(fi,ext)
%function fo = change_file_extension(fi,ext)

outputchar=0;
if ischar(fi)
    fi=cellstr(fi);
    outputchar=1;
end

for nb=1:length(fi)
    ffin = cellstr(fi{nb});
    
    for nbvol=1:length(ffin)
        [pp ff ee] = fileparts(deblank(ffin{nbvol}));
        if strcmp(ee,'.gz')
            [ppp ff ee] = fileparts(ff);
        end
        ffo{nbvol} = fullfile(pp,[ff,ext]);
    end
    fo{nb} = char(ffo);
    ffo = {};
end

if outputchar
    fo = char(fo);
end

