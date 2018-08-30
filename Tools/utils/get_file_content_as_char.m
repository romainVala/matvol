function content = get_file_content_as_char( filename )
% GET_FILE_CONTENT_AS_CHAR read the whole file as a single char

% Read the file
fid = fopen(deblank(filename), 'rt');
if fid == -1
    error('file cannot be opened : %s', deblank(filename))
end
content = fread(fid, '*char')'; % read the whole file as a single char
fclose(fid);

end % function
