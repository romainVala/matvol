function c=concat_cell_multi(c1,varargin)


for k=1:length(c1)
  
  aa=[cellstr(c1{k})];
  
  for nn = 1:length(varargin)
      aa = [aa; cellstr(varargin{nn}{k})];
  end
  
%  c{k} = char(aa);
  
  c{k} =(aa);
  
end
