function res = struct2res(s)

name = fieldnames(s(1));
res = struct;

for kn = 1:length(name)
    for k=1:length(s)
        val = getfield(s(k),name{kn});
        if isnumeric(val)
            if length(val)==1
                resval(k) = val;
            else
                resval{k} = val;
            end
        elseif isstruct(val)
            resval(k) = val;
        else
            resval{k} = val;
        end
        
    end
    res = setfield(res,name{kn},resval);
    clear resval
end

