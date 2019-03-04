function opennii(filename)
%OPENNII is called when you try to open a .nii file through Matlab. It can
%be a double click in Matlab GUI, or in the terminal "open myfile.nii".

unix(sprintf('LD_LIBRARY_PATH= mrview %s &',filename));

end % function
