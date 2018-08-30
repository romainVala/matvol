function [ out ] = copyObject( in , varargin )
%COPYOBJECT make a deep copy of the object, not just a pointer managment.
%
% Syntax : newMvArray = oldMvArray.copyObject();
%
% Warning : the argument "varargin" is reserved for internal purpose, do not use it.
% 

className = class(in);

% Prepare copy of potential objects inside (recursivity)
switch class(in)
    case 'exam'
        do_not_copy  = {};                 % up, copy pointers
        to_deep_copy = {'serie', 'model'}; % down, deep copy
        send_ptr     = {'exam'};           % send down pointers
    case 'serie'
        do_not_copy  = {'exam'};
        to_deep_copy = {'volume', 'stim', 'json'};
        send_ptr     = {'exam', 'serie'};
    case 'volume'
        do_not_copy  = {'exam', 'serie'};
        to_deep_copy = {};
        send_ptr     = {'exam', 'serie', 'volume'};
    case 'stim'
        do_not_copy  = {'exam', 'serie'};
        to_deep_copy = {};
        send_ptr     = {'exam', 'serie'};
    case 'model'
        do_not_copy  = {'exam'};
        to_deep_copy = {};
        send_ptr     = {'exam', 'model'};
    case 'json'
        do_not_copy  = {'exam', 'serie'};
        to_deep_copy = {};
        send_ptr     = {'exam', 'serie', 'json'};
    otherwise
        error('Unknown object class. Is it really an mvObject ?')
end

% Empty array of object, happens when copy a 0x0 array
if numel(in) == 0
    out = eval( sprintf('%s.empty',className) );
else
    % sorry this is a bit tricky to create dynamicly an array of objects
    eval( sprintf('out(%s) = %s;', regexprep(num2str(size(in)),'\s+',','), className) );
end

for idx = 1:numel(in)
    
    % New object, empty
    out(idx) = eval(className);
    
    % Pointer copy : receive from upper objects (containers)
    if ~isempty(varargin) && ~isempty(varargin{1})
        for var = 1 : numel(varargin{1})
            upperclassName = class(varargin{1}{var});
            out(idx).(upperclassName) = varargin{1}{var};
            if numel(out(idx).(upperclassName))>0
                assert( out(idx).(upperclassName) ~= in(idx).(upperclassName) , 'Problem in the copy of prointers from upper container' )
            end
        end
    end
    
    % Pointer copy : send to next
    ptrArray = cell(size(send_ptr));
    if ~isempty(send_ptr)
        for ptr = 1 : length(send_ptr)
            if strcmp(send_ptr{ptr},className)
                ptrArray{ptr} = out(idx);
                assert( out(idx) ~= in(idx) , 'Problem in the copy of prointers in the current object' )
            else
                ptrArray{ptr} = out(idx).(send_ptr{ptr});
                if numel(out(idx).(send_ptr{ptr}))>0
                    assert( out(idx).(send_ptr{ptr}) ~= in(idx).(send_ptr{ptr}) , 'Problem in the copy of prointers in the current object' )
                end
            end
        end
    end
    
    % Deep copy of objects
    for obj = 1 : length(to_deep_copy)
        out(idx).(to_deep_copy{obj}) = in(idx).(to_deep_copy{obj}).copyObject( ptrArray );
        assert( all( out(idx).(to_deep_copy{obj}) ~= in(idx).(to_deep_copy{obj}) ) , 'Problem in deep copy output from lower object' )
    end
    
    % Copy of non-objects
    propName = properties( in );
    for l =  1:length(to_deep_copy)
        where_cell = regexp(propName,to_deep_copy{l},'once');
        where_idx = cellfun( @isempty, where_cell, 'uniformoutput', 1);
        propName = propName(where_idx);
    end
    for l =  1:length(do_not_copy)
        where_cell = regexp(propName,do_not_copy{l},'once');
        where_idx = cellfun( @isempty, where_cell, 'uniformoutput', 1);
        propName = propName(where_idx);
    end
    for prop = 1 : length(propName)
        out(idx).(propName{prop}) = in(idx).(propName{prop});
    end
    
end % in(idx)

if isa(in,'exam')
    out = out';
end

% Check if a real deep copy has been done
assert( ~any(out(:)==in(:)) , 'Not a deep copy for the object %s ', className )

end % function
