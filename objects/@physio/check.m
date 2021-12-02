function check( physioArray )

if ~isvector(physioArray) % [ex,ser,phy]
    
    for ex = 1 : size(physioArray,1)
        for ser = 1 : size(physioArray,2)
            
            physioFile = physioArray(ex,ser,:).removeEmpty().getPath();
            nFile      = length(physioFile);
            
            recoding_duration = zeros(nFile,1);
            for iFile = 1 : nFile
                
                fname = physioFile{iFile};
                recoding_duration(iFile) = get_recoding_duration( fname );
                
            end % iFile
            
            fprintf('[%s]: %s \n', mfilename, fileparts(fname))
            for iFile = 1 : nFile
                [~,name] = fileparts(physioFile{iFile});
                fprintf('[%s]: %s = %g \n', mfilename, name, recoding_duration(iFile))
            end
            if rank(floor(recoding_duration)) == 0
                warning('[%s]: they mignt not have the same duration')
            end
            
        end % ser
    end % ex
    
else % [phy,1]
    
    physioFile  = physioArray.removeEmpty().getPath();
    physioFile  = sort(physioFile);
    nFile       = length(physioFile);
    
    for iFile = 1 : nFile
        
        fname = physioFile{iFile};
        recoding_duration = get_recoding_duration( fname );
        if recoding_duration > 1
            fprintf('[%s]: physio scan duration = %g %s \n', mfilename, recoding_duration, fname)
        end
        
    end % iFile
    
end

end % function


function recoding_duration = get_recoding_duration( fname )

dT = 2.5e-3; % in siemens device step time is 2.5ms

recoding_duration = -1; % initialization

content = get_file_content_as_char( fname );
content = regexprep( content, '\ +', ' '); % cleaning, delete multiple white spaces


content_split = strsplit(content,sprintf('\n'))'; % char -> cellstr
content_split(end) = []; % last one always empty
content_split = strtrim(content_split); % cleaning

first_lines = content_split(1:30); % for faster search

% LogDataType
idx_logdatatype = find(~cellfun('isempty', strfind(first_lines,'LogDataType')),1); %#ok<*STRCL1>
if isempty(idx_logdatatype)
    warning('[%s]: no line containing "LogDataType" detected in %s', mfilename, fname)
    return
end
res = strsplit(first_lines{idx_logdatatype}, '=');
LogDataType = strtrim( res{2} );


switch LogDataType
    case 'ACQUISITION_INFO'
        TARGET = 'ACQ_START_TICS';
    otherwise
        TARGET = 'ACQ_TIME_TICS';
end

% Extract useful content
idx_headerline = find(~cellfun('isempty', strfind(first_lines,TARGET)),1);
if isempty(idx_headerline)
    warning('[%s]: no line containing "%s" detected in %s', mfilename, TARGET, fname)
    return
end
idx_matrix = idx_headerline + 1;
content_useful = content_split(idx_matrix:end);

% just check first and last sample timestamp

switch LogDataType
    case 'ACQUISITION_INFO'
        result = regexp(content_useful([end-1 end]),'=','split');
        first_timestamp = str2double( result{1}{2} );
        last_timestamp  = str2double( result{2}{2} );
    otherwise
        result = regexp(content_useful([1 end]),'\s+','split');
        first_timestamp = str2double( result{1}{1} );
        last_timestamp  = str2double( result{2}{1} );
end
recoding_duration = (last_timestamp - first_timestamp) * dT; % seconds

end % function

