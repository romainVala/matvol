function varargout = seq2str( serieArray, param_list, identifier )
%SEQ2STR fetch the parameters in serieArray.sequence, according to the paramList.
% Then, converte them to a cellstr(dimension of serieArray)


%% Check input arguments

if nargin < 3
    identifier = '';
end

if nargin < 2 || isempty(param_list)
    param_list = {'TR', 'TE', 'seqname', 'pxdim', 'mxdim'};
end

nParam = length(param_list);


%% Prepare structure

cellstruct = cell(size(serieArray)); % pre-allocation
out        = cell(size(serieArray));

if numel(serieArray) > 0
    
    
    for idx = 1 : numel(serieArray)
        
        seq = serieArray(idx).sequence;
        if isempty(fieldnames(seq))
            continue
        end
        
        % only keep first echo
        if length(seq)>1
            allTE = [seq.EchoTime];
            [sortedTE,orderTE] = sort(allTE); %#ok<ASGLU>
            seq = seq(orderTE(1));
        end
        
        param = struct;
        for p = 1 : nParam
            switch param_list{p}
                
                % Deflaut parameters, all sequences
                case 'TR'
                    param.TR = seq.RepetitionTime*1000;
                case 'TE'
                    param.TE = seq.EchoTime*1000;
                case 'seqname'
                    param.seqname = seq.SequenceFileName;
                case 'pxdim'
                    param.pxdim = [seq.PixelSpacing' seq.SliceThickness];
                case 'mxdim'
                    param.mxdim = [seq.Rows seq.Columns seq.Slices];
                    
                    % Other parameters
                case 'TI'
                    param.TI = seq.InversionTime*1000;
                    
                    % unknown parameter ?
                otherwise
                    
                    if isfield(seq,param_list{p})
                        param.(param_list{p}) = seq.(param_list{p});
                    else
                        error('[%s]: "%s" not coded yet', mfilename, param_list{p} )
                    end
            end
        end
        
        cellstruct{idx} = param;
        
    end
    
    % Create an "empty" param structure, to fill the voids
    fields = fieldnames(param);
    empty_param = param;
    for f = 1 : length(fields)
        empty_param.(fields{f}) = '';
    end
    cellstruct(cellfun(@isempty,cellstruct)) = {empty_param}; % fill the voids
    
    
    %% Convert structure into char
    
    for idx = 1 : numel(serieArray)
        out{idx} = str2char(cellstruct{idx},identifier);
    end
    
    
end


%% Output

if nargout
    varargout{1} = out;
    varargout{2} = cellstruct;
    varargout{3} = param_list; % in case of using default param_list
else
    disp(char(out(:)'))
end


end % function
