function [tracks file] = read_mrtrix_tracks_hdr (filename)

% function: tracks = read_mrtrix_tracks_hdr (filename)
%
% returns a structure containing the header information and data for the MRtrix 
% format image 'filename' (i.e. files with the extension '.mif' or '.mih').

if iscell(filename)
  for k=1:length(filename)
    tracks(k) = read_mrtrix_tracks_hdr (filename{k});
  end
  return
end


f = fopen (filename, 'r');
if (f<1) 
  disp (['error opening ' filename ]);
  return
end
L = fgetl(f);
if ~strncmp(L, 'mrtrix tracks', 13)
  fclose(f);
  disp ([filename ' is not in MRtrix format']);
  return
end

tracks = struct();

while 1
  L = fgetl(f);
  if ~ischar(L), break, end;
  L = strtrim(L);
  if strcmp(L, 'END'), break, end;
  d = strfind (L,':');
  if isempty(d)
    disp (['invalid line in header: ''' L ''' - ignored']);
  else
    key = lower(strtrim(L(1:d(1)-1)));
    value = strtrim(L(d(1)+1:end));
    if strcmp(key, 'file')
      file = value;
    elseif strcmp(key, 'datatype')
      tracks.datatype = value;
    elseif strcmp(key, 'roi')
      ind=findstr(value,' ');
      key = [key '_' value(1:ind(1)-1)];
      value(1:ind(1))='';
      tracks.datatype = value;
      tracks = setfield (tracks, key, value);

    else 
      if ~isempty(str2num(value))
	value=str2num(value);
      end
	
      tracks = setfield (tracks, key, value);
    end
  end
end
fclose(f);

if ~exist ('file') || ~isfield (tracks, 'datatype')
  disp ('critical entries missing in header - aborting')
  return
end

