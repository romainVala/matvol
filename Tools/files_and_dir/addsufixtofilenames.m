function newlist = addsufixtofilenames(filelist,prefix)
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
        %
        %             [pth,nm,xt,vr] = fileparts(deblank(filelist{i}(img,:)));
        %
        %             %for double extention (.nii.gz)
        %             [pth2,nm2,xt2,vr2] = fileparts(nm);
        %             if ~isempty(xt2)
        %                 xt = [xt2 xt];
        %                 nm = nm2;
        %             end
        %             wfiles  = strvcat(wfiles, fullfile(pth,[nm prefix xt  vr]));
        %         catch
        [pth,nm,xt] = fileparts(deblank(filelist{i}(img,:)));
        
        %for double extention (.nii.gz)
        [pth2,nm2,xt2] = fileparts(nm);
        if ~isempty(xt2)
            xt = [xt2 xt];
            nm = nm2;
        end
        
        if iscell(prefix)
            pref=prefix{i};
        else
            pref = prefix;
        end
        
        wfiles  = strvcat(wfiles, fullfile(pth,[nm pref xt ]));
        %         end
    end
    newlist{i}=wfiles;
end

if nocell
    newlist=char(newlist);
end
