function newlist = addprefixtofilenames(filelist,prefix)
% filelist must be a cell array where each element is a char-array
% containing a list of file names.

nocell=0;

if ~iscell(filelist)
    filelist={filelist};
    nocell=1;
end

newlist=cell(1,length(filelist));

for i=1:length(filelist)
    wfiles=[];
    for img=1:size(filelist{i},1)
        %         try
        %             [pth,nm,xt,vr] = fileparts(deblank(filelist{i}(img,:)));
        %             wfiles  = strvcat(wfiles, fullfile(pth,[prefix nm xt vr]));
        %         catch
        [pth,nm,xt] = fileparts(deblank(filelist{i}(img,:)));
        
        if iscell(prefix)
            pref=prefix{i};
        else
            pref = prefix;
        end
        
        wfiles  = strvcat(wfiles, fullfile(pth,[pref nm xt ]));
        %        end
    end
    newlist{i}=wfiles;
end

if nocell
    newlist=char(newlist);
end
