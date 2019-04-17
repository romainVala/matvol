function []=r_dir(d)

d = cellstr(d); % assert cellstr

for k=1:length(d)
    %dir(d{k});
    unix(sprintf('ls -ltra "%s"',d{k}))
end % function
