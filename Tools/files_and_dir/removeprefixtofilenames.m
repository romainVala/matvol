function newlist = removeprefixtofilenames(filelist,prefix)
% filelist must be a cell array where each element is a char-array
% containing a list of file names.

newlist=cell(1,length(filelist));

for i=1:length(filelist)
    wfiles=[];
    for img=1:size(filelist{i},1)
        [pth,nm,xt] = fileparts(deblank(filelist{i}(img,:)));

	%if nm(1)==prefix
	%  nm(1)=[];
	%end
	if strcmp (nm(1:length(prefix)),prefix)
	   nm(1:length(prefix))=[];
	end

        wfiles  = strvcat(wfiles, fullfile(pth,[ nm xt ]));
    end
    newlist{i}=wfiles;
end
