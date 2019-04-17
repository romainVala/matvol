function [ out, content ] = get_string_from_json( filename , field_to_get , field_type )
%GET_STRING_FROM_JSON extracts some values from a JSON file
%
%   SYNTHAX :
%   [ out ] = get_string_from_json( filename , field_to_get , field_type )
%
%   INPUT :
%   filename     : char
%   field_to_get : cell of strings
%   field_type   : cell of strings

% Made to replace loadjson form jsonlab

%% Check inpur parameters

assert(nargin==3,'Wrong number of input arguments : 3 required')

assert(ischar(filename) || iscellstr(filename),'filename must be a char or cellstr')

assert((iscellstr(field_to_get)||ischar(field_to_get))&&isvector(field_to_get),'field_to_get cellstr')
assert((iscellstr(field_type  )||ischar(field_type  ))&&isvector(field_type  ),'field_type cellstr')

field_to_get = cellstr(field_to_get);
field_type   = cellstr(field_type);

assert(numel(field_to_get)==numel(field_type),'field_to_get field_type must have the same dimension')

assert(all(cellfun(@ischar,field_to_get)),'all elements in field_to_get must be char')
assert(all(cellfun(@ischar,field_type)),'all elements in field_type must be char')


%% Loop over all files

if iscellstr(filename)
    out = cell(length(filename),1);
    for kk=1:length(filename)
        out{kk} = get_string_from_json( filename{kk} , field_to_get , field_type );
    end
    return
end


%% Read the file

content = get_file_content_as_char( filename );


%% Extract tokens

out = cell(length(field_to_get),1);

for o = 1 : length(field_to_get)
    
    switch field_type{o}
        
        case { 'double' , 'num' , 'numeric' }
            
            token = regexp(content, [ '"' field_to_get{o} '": (([-e.]|\d)+),' ],'tokens');
            if ~isempty(token)
                out{o} = str2double( token{:} );
            else
                out{o} = [];
            end
            
        case { 'char' , 'string' , 'str' }
            
            token = regexp(content, [ '"' field_to_get{o} '": "([A-Za-z0-9-_,;^]+)",' ],'tokens');
            if ~isempty(token)
                out{o} = token{:}{:};
            else
                out{o} = [];
            end
            
        case {'vect'}
            
            start = regexp(content, [ '"' field_to_get{o} '": [' ]);
            stop = regexp(content(start:end),']','once');
            
            VECT_str = content(start:start+stop);
            
            VECT_cell_raw = strsplit(VECT_str,'\n')';
            VECT_cell = VECT_cell_raw(cellfun( @isempty, regexp(VECT_cell_raw,'\[|\]') ));
            VECT_cell_nocoma = strrep(VECT_cell,',','');
            VECT_cell_nocoma_nowhitespace = strrep(VECT_cell_nocoma,' ','');
            VECT_char = char(VECT_cell_nocoma_nowhitespace);
            
            out{o} = str2num(VECT_char); %#ok<ST2NM> % str2double does not work
            
        otherwise
            error('unrecognized type : %s',field_type{o})
    end
    
end

end % function
