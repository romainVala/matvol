function opengz(filename)
%OPENGZ is called when you try to open a .nii.gz file through Matlab. It
%can be a double click in Matlab GUI, or in the terminal "open
%myfile.nii.gz".

[~, name, ~] = fileparts(filename);
if strfind(name,'.nii') %#ok<STRIFCND>
    unix(sprintf('LD_LIBRARY_PATH= mrview %s &',filename));
end

end % function
