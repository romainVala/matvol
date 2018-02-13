function [ out ] = get_string_from_json( filename , field_to_get , field_type )
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

assert(ischar(filename),'filename must be a char')

assert(iscell(field_to_get)&&isvector(field_to_get),'field_to_get cellvector')
assert(iscell(field_type)&&isvector(field_type),'field_type cellvector')

assert(numel(field_to_get)==numel(field_type),'field_to_get field_type must have the same dimension')

assert(all(cellfun(@ischar,field_to_get)),'all elements in field_to_get must be char')
assert(all(cellfun(@ischar,field_type)),'all elements in field_type must be char')


%% Read the file

fid = fopen(filename, 'rt');
if fid == -1
    error('file cannot be opened : %s',filename)
end
content = fread(fid, '*char')'; % read the whole file as a single char
fclose(fid);


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
            token = regexp(content, [ '"' field_to_get{o} '": "([A-Za-z0-9-_,;]+)",' ],'tokens');
            if ~isempty(token)
                out{o} = token{:}{:};
            else
                out{o} = [];
            end
        otherwise
            error('unrecognized type : %s',field_type{o})
    end
    
end

end % function
