function c=concat_cell(c1,varargin)


for k=1:length(c1)
    
    if iscell(c1{k})  %after a get_multi
        
        aa=[cellstr(c1{k})];
        
        for nn = 1:length(varargin)
            aa = [aa, varargin{nn}{k}];
        end
        
        c{k} = aa;
  
        
        
    else
        
        aa=[cellstr(c1{k})];
        
        for nn = 1:length(varargin)
            aa = [aa; cellstr(varargin{nn}{k})];
        end
        
        c{k} = char(aa);
    end
end
