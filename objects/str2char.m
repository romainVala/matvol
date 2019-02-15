function str = str2char( content, name )
%GEN_SERIE_NAME
%
% Exemple :
%
% param.TR = 1520;
% param.TE = 30;
% param.seqname = 'cmrr_mbep2d_bold';
% param.mlchar = ['ffff';'gggg'];
% param.pxdim = [1.7 1.7 2];
% param.mxdim = [210 212 56];
% param.numepty = [];
%
% str2char(param,'dwi')
%
% ans =
%     'dwi: TR=1520 TE=30 seqname=cmrr_mbep2d_bold mlchar=ffffgggg pxdim=1.7x1.7x2 mxdim=210x212x56 numepty=[]'
%

%% Check input arguments

if nargin < 1
    help(mfilename)
    return
end

if nargin < 2
    name = '';
end

assert( ischar  (name   ) , 'name must be a char'      )
assert( isstruct(content) , 'content must be a struct' )


%% Concat name and content into a char

if isempty(name)
    str = '';
else
    str = [name ':'];
end

fields = fieldnames(content);

for i = 1  : length(fields)
    
    fname   = fields{i};
    current = content.(fname);
    sze = size (current);
    nbr = numel(current);
    
    if isa(current,'double')
        if nbr == 0
            str = sprintf('%s %s=[]',str,fname);
        elseif nbr == 1
            str = sprintf('%s %s=%g',str,fname,current);
        else
            rep      = repmat('%gx',[1 nbr]);
            rep(end) = [];
            str = sprintf(['%s %s=' rep],str,fname,current);
        end
        
    elseif isa(current,'char')
        if nbr==0 % empty char
            % pass
        elseif sze(1) > 1 % multi ligne
            tmp = reshape(current', [1 nbr]);
            str = sprintf('%s %s=%s',str,fname,tmp);
        else
            str = sprintf('%s %s=%s',str,fname,current);
        end
        
    end
    
end

if isempty(name) && ~isempty(str)
    str(1) = [];
end


end % function
