function dir_out = r_mkdir(d,new_dir)

if nargin==1
    new_dir='';
end

if isstr(d)
  d = repmat({d},size(new_dir));
end

if isstr(new_dir)
  new_dir = repmat({new_dir},size(d));
end


if any(size(d)-size(new_dir))
  error('rrr \n the 2 cell input must have the same size\n')
end

  
for k=1:length(d)
  dir_out{k} = [fullfile(d{k},new_dir{k}) filesep];
  if ~exist(dir_out{k})
    mkdir(dir_out{k});
  end
  
end  
