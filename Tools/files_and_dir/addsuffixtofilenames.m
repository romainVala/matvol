function newlist = addsuffixtofilenames(filelist,suffix)
% ADDSUFFIXTOFILENAMES Adds suffixs to files name.
%
% 1. filelist can be a cell-array where each element is a char-array
% containing a list of file names.
%
% 2. filelist can be a char-array containing a list of file names.
%
% suffix can be char : suffix will be applied to each elements of the
% filelist{i}.
%
% suffix can be cell-array of char : suffix{i} will be applied to each
% elements of the filelist{i}.
%
% note : the 'filelist' will remain a char or a cell, depending on its
% nature.
%

%% Check input arguments

if nargin ~= 2
    error('filelist & suffix must be defined')
end


%% Prepare inputs and outputs format

suffix = cellstr(suffix); % avoid problems of class or dimensions

% If the filelist is char, we want the newlist to also be char
makeitchar = 0;
if ischar(filelist)
    filelist   = cellstr(filelist);
    makeitchar = 1;
end

% Repeat suffix to match filelist size if needed
if numel(suffix) == 1
    suffix = repmat(suffix,size(filelist));
end

if numel(filelist) > numel(suffix)
    error('Dimensions mismatch : if there is N elements in filelist, there must be N suffix, OR juste 1 suffix')
end


%% Add the suffixs

newlist = cell(length(filelist),1);

for i=1:length(filelist)
    
    wfiles = [];
    filelistchar = char(filelist{i}); %for case where you have cell of cell
    for line = 1:size(filelistchar,1)
        
        [pathstr,name,extension] = fileparts(deblank(filelistchar(line,:)));
        
        %for double extention (.nii.gz)
        [~,nm2,xt2] = fileparts(name);
        if ~isempty(xt2)
            extension = [xt2 extension]; %#ok<AGROW>
            name = nm2;
        end
        
        
        wfiles  = strvcat(wfiles , fullfile(pathstr,[name suffix{i} extension ]));
        
    end
    
    newlist{i} = wfiles;
    
end

if makeitchar
    newlist = char(newlist);
end

end % function
