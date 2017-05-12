function regr = searchCondInOnsetMatfiles(fileList, cond, rp)

regr = [];

for f = 1:length(fileList)
    load(fileList{f});
    for i = 1:length(names)
        if regexp(names{i}, cond)
            regr = [regr 1];
        else
            regr = [regr 0];
        end
    end
    
    if rp
        regr = [regr 0 0 0 0 0 0];
    end
end
