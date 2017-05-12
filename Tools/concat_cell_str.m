function c=concat_cell_str(c1,varargin)

c=cell(size(c1));

for k=1:length(c1)
    aa = c1{k};
    for nn = 1:length(varargin)
        if isstr(varargin{nn})
            bb=varargin{nn};
        else
            bb=varargin{nn}{k};
        end
        aa = [aa, bb ];
    end
    
    
    c{k} = aa;
    
end
